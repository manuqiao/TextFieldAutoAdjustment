//
//  ViewController.m
//  test
//
//  Created by ManuQiao on 16/7/1.
//  Copyright © 2016年 ManuQiao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITextFieldDelegate> {
    BOOL _isKeyboardShowing;
    UITextField *_activeTextField;
    BOOL _addedObserver;
    NSArray *_inputFocuses;
    BOOL _pressedReturn;
    float _keyboardHeight;
    BOOL _invokeDelegateNow;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if (!_addedObserver) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        _addedObserver = YES;
    }
    _textField1.delegate = self;
    _textField2.delegate = self;
    _textField3.delegate = self;
    _inputFocuses = [NSArray arrayWithObjects:_textField1, _textField2, _textField3, nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)click:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Job Done!"delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    NSLog(@"location : (%.2f,%.2f)", location.x, location.y);
    if (_isKeyboardShowing && _activeTextField) {
        [_activeTextField resignFirstResponder];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    int index = [_inputFocuses indexOfObject:textField];
    if (index == [_inputFocuses count] - 1) {//如果是最后一个text field时按return 就点击按钮
        [self click:_button];
        [self hideKeyBoard];
    }
    else {//如果没有到最后一个text field就将焦点转向下一个text field
        UITextField *nextTextField = [_inputFocuses objectAtIndex:(index + 1)];
        [nextTextField becomeFirstResponder];
        [self autoAdjustTextFieldHeight:nextTextField];
    }
    UITextField *currentTextField = [_inputFocuses objectAtIndex:index];
    [currentTextField resignFirstResponder];
    return NO;
}

// 点击文本框会先触发这个代理
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _pressedReturn = NO;//按下return和直接点击text field都会触发这个方法，所以用一个标示的变量来区分，后面会发挥作用的。
    _activeTextField = textField;
    
    //重要：这里的_invokeDelegateNow标记的作用是这样的，用户点击文本框会先触发这个代理方法，此时没有从KeyboardWillShow:的实现中获取键盘高度。_invokeDelegateNow会在KeyboardWillShow:中被标记为YES然后手动再次调用这个代理方法（不是由系统调用）。此时再执行调整视图高度的操作，才能根据键盘高度来调整。
    if (_invokeDelegateNow) {
        [self autoAdjustTextFieldHeight:textField];
    }
}

- (void)autoAdjustTextFieldHeight:(UITextField *)textField
{
    CGRect frame = textField.frame;
    CGPoint point = frame.origin;
    CGRect viewBounds = self.view.bounds;
    
    int offset = point.y + frame.size.height - (viewBounds.size.height - _keyboardHeight);
    
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
    self.view.bounds = CGRectMake(0, offset > 0 ? ABS(offset) : 0, viewBounds.size.width, viewBounds.size.height);
    
    [UIView commitAnimations];
}

#pragma mark - KeyboardNotification

// 触发文本框代理以后触发这个消息
- (void)KeyboardWillShow:(NSNotification *)notification {
    _isKeyboardShowing = YES;
    
    NSDictionary *info = [notification userInfo];
    
    //获取高度
    NSValue *value = [info objectForKey:@"UIKeyboardBoundsUserInfoKey"];
    if (!value) {
        @throw [NSException exceptionWithName:@"error when getting Keyboard Rect" reason:@"maybe not supported in sdk" userInfo:nil];
    }
    
    CGSize keyboardSize = [value CGRectValue].size;
    _keyboardHeight = keyboardSize.height;
    
    _invokeDelegateNow = YES;
    [self textFieldDidBeginEditing:_activeTextField];
}

- (void)KeyboardWillHide:(NSNotification *)notification {
    _isKeyboardShowing = NO;
    if (!_pressedReturn) {
        [self hideKeyBoard];
    }
    else {
        _pressedReturn = NO;
    }
}

- (void)hideKeyBoard {
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
    self.view.bounds =CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [UIView commitAnimations];
}

@end
