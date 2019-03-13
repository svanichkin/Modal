//
//  Modal.m
//  v.1.1
//
//  Created by Сергей Ваничкин on 12/3/18.
//  Copyright © 2018 Macflash. All rights reserved.
//

#import "Modal.h"

#define ENABLE_LOG NO

@interface ModalItem : NSObject

@property (nonatomic, copy  ) ModalCompletion   completion;
@property (nonatomic, assign) BOOL              animated;
@property (nonatomic, assign) BOOL              query;
@property (nonatomic, assign) BOOL              navigation;
@property (nonatomic, assign) BOOL              navigationHidden;
@property (nonatomic, strong) UIViewController *controller;

@end

@implementation ModalItem

-(NSString *)description
{
    return
    [NSString stringWithFormat:@"{controller: %@, animated: %@, query: %@, navigation: %@, navigationHidden: %@, completion:%@}",
     self.controller,
     self.animated         ? @"YES" : @"NO",
     self.query            ? @"YES" : @"NO",
     self.navigation       ? @"YES" : @"NO",
     self.navigationHidden ? @"YES" : @"NO",
     self.completion];
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
    UIWindow *window =
    UIWindow.new;
    
    window.backgroundColor =
    UIColor.clearColor;
    
    [window makeKeyAndVisible];
    
    NSInteger maxZOrder = NSIntegerMin;
    
    for (UIWindow *w in UIApplication.sharedApplication.windows)
        if (w.windowLevel > maxZOrder && w != window)
            maxZOrder = window.windowLevel;
    
    window.windowLevel = maxZOrder + 1;
    
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

-(void)showViewController:(UIViewController *)viewController
                  options:(ModalOptions      )options
               completion:(ModalCompletion   )completion;
{
    if (viewController == nil)
        return;
 
    self.progress = YES;
    
    ModalItem *item =
    ModalItem.new;
    
    item.animated          = !(options & ModalOptionNoAnimated);
    item.query             = options & ModalOptionQuery;
    item.navigation        = options & ModalOptionNavigation;
    item.navigationHidden  = options & ModalOptionNavigationHidden;
    item.completion        = completion;
    item.controller        = viewController;

    // Если в очереди ещё нет контроллера из очедери ожидания
    // или нужно немедленно отобразить контроллер
    if (item.query             == NO ||
        self.waitingItemShowed == NO)
    {
        [self.showedItems addObject:item];
        
        [self showWindowWithItem:item
                      completion:^
        {
            if (ENABLE_LOG)
            {
                NSLog(@"New showed item: %@", item);
                NSLog(@"Items waiting: %@", self.waitingItems);
                NSLog(@"Showed items: %@", self.showedItems);
            }

            if (item.completion)
                item.completion();

            self.progress = NO;
            
            if (self.showedItems.count)
                [self startTimer];
        }];

        return;
    }

    [self.waitingItems addObject:item];

    if (ENABLE_LOG)
    {
        NSLog(@"New waiting item: %@", item);
        NSLog(@"Items waiting: %@", self.waitingItems);
        NSLog(@"Showed items: %@", self.showedItems);
    }

    self.progress = NO;
}

-(void)refreshDismissedItems:(NSArray *)dismissedItems
{
    self.progress = YES;
    
    if (ENABLE_LOG)
    {
        NSLog(@"New items dismissed: %@", dismissedItems);
        NSLog(@"Items waiting: %@", self.waitingItems);
        NSLog(@"Showed items: %@", self.showedItems);
    }

    // Удалим из очереди
    [self.showedItems removeObjectsInArray:dismissedItems];

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
    
    [self.showedItems     addObject:item];
    [self.waitingItems removeObject:item];
    
    [self showWindowWithItem:item
                  completion:^
    {
         if (ENABLE_LOG)
         {
             NSLog(@"New showed item: %@", item);
             NSLog(@"Items waiting: %@", self.waitingItems);
             NSLog(@"Showed items: %@", self.showedItems);
         }
         
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

