//
//  Modal.h
//  v.1.6
//
//  Created by Сергей Ваничкин on 12/3/18.
//  Copyright © 2018 Macflash. All rights reserved.
//
//  Данный класс используется для таких задач как поках окон в произвольном месте
//  в произвольное время, без ограничений.
//
//  Например задача показать окно пинкода, и одновременно с ним окно блокировки
//  для встроенных покупок или ограничения триал версии приложения.
//  Этот класс автоматически создает очередь из таких окно.
//  Удалять окна можно как обычно через dismiss.
//
//  Показать контроллер немендленно
//
//  [Modal.current showViewController:controller
//                            options:kNilOptions
//                         completion:nil];
//
//  Показать контроллер, через очередь
//
//  [Modal.current showViewController:controller
//                            options:ModalOptionQuery
//                         completion:nil];
//
//  Показать контроллер немендленно, обернутый в контроллер навигации
//
//  [Modal.current showViewController:controller
//                            options:ModalOptionNavigation
//                         completion:nil];
//
//  Показать контроллер немендленно, обернутый в контроллер навигации, со скрытым меню
//
//  [Modal.current showViewController:controller
//                            options:ModalOptionNavigation|ModalOptionNavigationHidden
//                         completion:nil];
//
//  Также есть возможность проксировать нажатия view на нижние слои. Например
//  нам нужно что бы окно которое сейачс открыто было прозрачным для нажатий
//  (т.е. нажатия передавались окну которое ниже). Для этого достаточчно указать
//  для UIView параметр proxyUserInteractionEnabled = YES.
//  Если указать этот ключ для UIView являющегося самым нижним слоем контроллера
//  то все окно станет прозрачным для нажатий.
//

#import <UIKit/UIKit.h>

@interface UIView (ProxyUserInteraction)

@property (nonatomic, assign) IBInspectable BOOL proxyUserInteractionEnabled;

@end

@interface UIViewController (Storyboard)

+(instancetype)newFromStoryboard;

@end

typedef enum
{
    ModalOptionNone                      = 0,
    ModalOptionNoAnimated                = 1 << 0,
    ModalOptionQuery                     = 1 << 1,
    ModalOptionNavigation                = 1 << 2,
    ModalOptionNavigationHidden          = 1 << 3
} ModalOptions;

typedef void(^ModalCompletion)(void);

@interface Modal : NSObject

+(void)showViewController:(UIViewController  *)viewController
                  options:(ModalOptions       )options
               completion:(ModalCompletion    )completion;

@end
