//
//  Modal.m
//  v.1.8
//
//  Created by Сергей Ваничкин on 12/3/18.
//  Copyright © 2018 Macflash. All rights reserved.
//

#import "Modal.h"
#import <objc/runtime.h>

#define ENABLE_LOG NO

@implementation UIView (ProxyUserInteraction)

-(void)setProxyUserInteractionEnabled:(BOOL)proxyUserInteractionEnabled
{
    objc_setAssociatedObject(self,
                             @"proxyUserInteractionEnabled",
                             @(proxyUserInteractionEnabled),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(BOOL)proxyUserInteractionEnabled
{
    NSNumber *enabled =
    objc_getAssociatedObject(self,
                             @"proxyUserInteractionEnabled");
    
    return enabled.boolValue;
}

@end

@implementation UIViewController (Storyboard)

+(instancetype)newFromStoryboard
{
    UIStoryboard *storyboard =
    [UIStoryboard storyboardWithName:@"Main"
                              bundle:nil];
    
    if (storyboard == nil)
        storyboard =
        [UIStoryboard storyboardWithName:@"MainStoryboard"
                                  bundle:nil];
    
    if (storyboard == nil)
    {
        if (ENABLE_LOG)
            NSLog(@"Error in newFromStoryboard. Storyboard not found.");
        
        return nil;
    }
    
    NSString *identifier =
    NSStringFromClass(self);
    
    UIViewController *controller =
    [storyboard instantiateViewControllerWithIdentifier:identifier];
    
    if (controller == nil)
    {
        if (ENABLE_LOG)
            NSLog(@"\nError in newFromStoryboard. Identifier %@ not found on stroryboard.",
                  identifier);
        
        return nil;
    }
    
    return controller;
}

@end

@interface ModalItem : NSObject

@property (nonatomic, copy  ) ModalCompletion   completion;
@property (nonatomic, assign) BOOL              animated;
@property (nonatomic, assign) BOOL              query;
@property (nonatomic, assign) BOOL              navigation;
@property (nonatomic, assign) BOOL              navigationHidden;
@property (nonatomic, assign) BOOL              proxyUserInteraction;
@property (nonatomic, assign) BOOL              alwaysOnTop;
@property (nonatomic, strong) UIViewController *controller;

@end

@implementation ModalItem

-(NSString *)description
{
    return
    [NSString stringWithFormat:@"{controller: %@, animated: %@, query: %@, navigation: %@, navigationHidden: %@, completion:%@, alwaysOnTop:%@}",
     self.controller,
     self.animated         ? @"YES" : @"NO",
     self.query            ? @"YES" : @"NO",
     self.navigation       ? @"YES" : @"NO",
     self.navigationHidden ? @"YES" : @"NO",
     self.alwaysOnTop      ? @"YES" : @"NO",
     self.completion];
}

@end

@interface ProxyWindow : UIWindow
@end

@implementation ProxyWindow

-(UIView *)hitTest:(CGPoint  )point
         withEvent:(UIEvent *)event
{
    UIView *view =
    [super hitTest:point
         withEvent:event];
    
    if (view.proxyUserInteractionEnabled == NO)
        return view;
    
    view =
    [self proxedSuperviewWithView:view];

    if (view.superview == nil ||
        (view.superview != self &&
         [self.subviews containsObject:view.superview]) == NO)
        return view;
    
    NSInteger index =
    [UIApplication.sharedApplication.windows indexOfObject:self];
    
    if (index - 1 < 0)
        return
        view;
    
    UIWindow *window =
    UIApplication.sharedApplication.windows[index - 1];
    
    return
    [window hitTest:point
          withEvent:event];
}

-(UIView *)proxedSuperviewWithView:(UIView *)view
{
    UIView *superview = view.superview;
    
    if (superview == nil)
        return view;
    
    if (superview.proxyUserInteractionEnabled)
        return
        [self proxedSuperviewWithView:view];
    
    return view;
}

@end

@interface Modal ()

// здесь контроллеры ожидающие показа (query YES)
@property (nonatomic, strong) NSMutableArray <ModalItem *> *waitingItems;

// здесь контроллеры уже отображенные
@property (nonatomic, strong) NSMutableArray <ModalItem *> *showedItems;

// определение закрытых окон по таймеру (увы решения лучше пока не найдено)
@property (nonatomic, strong) NSTimer                      *timer;
@property (nonatomic, assign) BOOL                          progress;

@end

@implementation Modal

+(instancetype)current
{
    static Modal *_current = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^
    {
        _current = Modal.new;
    });
    
    return _current;
}

-(instancetype)init
{
    if (self = [super init])
    {
        self.waitingItems =
        NSMutableArray.new;
        
        self.showedItems =
        NSMutableArray.new;
    }
    
    return self;
}

-(void)showWindowWithItem:(ModalItem     *)item
               completion:(ModalCompletion)completion
{
    ProxyWindow *window =
    ProxyWindow.new;
    
    window.backgroundColor =
    UIColor.clearColor;
    
    window.windowLevel = self.maxZOrder + 1;
    
    [window makeKeyAndVisible];
    
    [self arrageZOrders];
    
    window.rootViewController =
    UIViewController.new;
    
    if (item.navigation)
    {
        UINavigationController *navigationController =
        [UINavigationController.alloc initWithRootViewController:item.controller];
        
        navigationController.navigationBarHidden =
        item.navigationHidden;
        
        [window.rootViewController
         presentViewController:navigationController
         animated:item.animated
         completion:completion];
    }
    
    else
        [window.rootViewController
         presentViewController:item.controller
         animated:item.animated
         completion:completion];
    
    // Так же нужно учесть уже отображающиеся окна с AlwayOnTop,
    // т.е. такие окна, которые должны быть показаны выше текущих
    
    NSMutableArray *showedInverse = self.showedItems.reverseObjectEnumerator.allObjects.mutableCopy;
    
    for (ModalItem *modalItem in showedInverse)
        if (modalItem.alwaysOnTop)
            [self windowOnView:modalItem.controller.view].windowLevel =
            self.maxZOrder + 1;
    
    [self arrageZOrders];
}

-(UIWindow *)windowOnView:(UIView *)view
{
    if (view == nil)
        return nil;
    
    if (view.window)
        return
        view.window;
    
    return
    [self windowOnView:view.superview];
}

-(NSInteger)maxZOrder
{
    NSInteger maxZOrder = NSIntegerMin;
    
    for (UIWindow *w in UIApplication.sharedApplication.windows)
        if (w.windowLevel > maxZOrder)
            maxZOrder = w.windowLevel;
    
    return maxZOrder;
}

-(void)arrageZOrders
{
    NSInteger i = 0;
    
    for (UIWindow *window in UIApplication.sharedApplication.windows)
    {
        window.windowLevel = i;
        
        i ++;
    }
}

-(void)startTimer
{
    if (self.timer)
        return;
    
    self.timer =
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                    repeats:YES
                                      block:^(NSTimer *timer)
    {
        if (self.progress)
            return;

        NSMutableArray <ModalItem *> *dismessedItems =
        NSMutableArray.new;
        
        // Пробегаем по нашим отображаемым контроллерам
        for (ModalItem *item in self.showedItems)
            // Если контроллер был dissmissed добавим в массив
            if (item.controller                                &&
                item.controller.view.superview          == nil &&
                item.controller.presentedViewController == NO)
                [dismessedItems addObject:item];
        
        if (dismessedItems.count)
            [self refreshDismissedItems:dismessedItems.copy];
    }];
}

-(void)stopTimer
{
    [self.timer invalidate];
    
    self.timer = nil;
}

+(void)showViewController:(UIViewController *)viewController
                  options:(ModalOptions      )options
               completion:(ModalCompletion   )completion;
{
    if (viewController == nil)
        return;
    
    Modal *modal = Modal.current;
 
    modal.progress = YES;
    
    ModalItem *item =
    ModalItem.new;
    
    item.animated          = !(options & ModalOptionNoAnimated);
    item.query             = options & ModalOptionQuery;
    item.navigation        = options & ModalOptionNavigation;
    item.navigationHidden  = options & ModalOptionNavigationHidden;
    item.alwaysOnTop       = options & ModalOptionAlwaysOnTop;
    item.completion        = completion;
    item.controller        = viewController;

    // Если в очереди ещё нет контроллера из очедери ожидания
    // или нужно немедленно отобразить контроллер
    if (item.query              == NO ||
        modal.waitingItemShowed == NO)
    {
        [modal.showedItems addObject:item];
        
        [modal showWindowWithItem:item
                       completion:^
        {
            if (ENABLE_LOG)
                NSLog(@"\nNew showed item: %@\nItems waiting: %@\nShowed items: %@",
                      item,
                      modal.waitingItems,
                      modal.showedItems);

            if (item.completion)
                item.completion();

            modal.progress = NO;
            
            if (modal.showedItems.count)
                [modal startTimer];
        }];

        return;
    }

    [modal.waitingItems addObject:item];

    if (ENABLE_LOG)
        NSLog(@"\nNew waiting item: %@\nItems waiting: %@\nShowed items: %@",
              item,
              modal.waitingItems,
              modal.showedItems);

    modal.progress = NO;
}

-(void)refreshDismissedItems:(NSArray *)dismissedItems
{
    self.progress = YES;
    
    // Удалим из очереди
    [self.showedItems removeObjectsInArray:dismissedItems];
    
    [self arrageZOrders];
    
    if (ENABLE_LOG)
        NSLog(@"\nNew items dismissed: %@\nItems waiting: %@\nShowed items: %@",
              dismissedItems,
              self.waitingItems,
              self.showedItems);

    // Если в очереди ожидания есть ожидающие показа
    // но, если уже отображается один из них, ничего не делаем
    if (self.waitingItems.count &&
        self.waitingItemShowed)
    {
        self.progress = NO;
        
        return;
    }
    
    // Если очередь ожидания пустая и очередь отображения пустая
    // скроем наше окно и остановим таймер
    if (self.waitingItems.count == 0 &&
        self.showedItems.count  == 0)
    {
        self.progress = NO;

        [self stopTimer];
        
        return;
    }
    
    // Добавим из очереди ожидания новый контроллер
    ModalItem *item =
    self.waitingItems.firstObject;
    
    if (item == nil)
    {
        self.progress = NO;
        
        return;
    }
    
    [self.showedItems     addObject:item];
    [self.waitingItems removeObject:item];
    
    [self showWindowWithItem:item
                  completion:^
    {
         if (ENABLE_LOG)
             NSLog(@"\nNew showed item: %@\nItems waiting: %@\nShowed items: %@",
                   item,
                   self.waitingItems,
                   self.showedItems);
        
         if (item.completion)
             item.completion();
         
         self.progress = NO;
     }];
}

-(BOOL)waitingItemShowed
{
    for (ModalItem *item in self.showedItems)
        if (item.query == YES)
            return YES;
    
    return NO;
}

@end

