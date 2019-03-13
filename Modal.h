//
//  Modal.h
//  v.1.1
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

#import <UIKit/UIKit.h>

typedef enum
{
    ModalOptionNone                 = 0,
    ModalOptionNoAnimated           = 1 << 0,
    ModalOptionQuery                = 1 << 1,
    ModalOptionNavigation           = 1 << 2,
    ModalOptionNavigationHidden     = 1 << 3
} ModalOptions;

typedef void(^ModalCompletion)(void);

@interface Modal : NSObject

+(instancetype)current;

-(void)showViewController:(UIViewController *)viewController
                  options:(ModalOptions      )options
               completion:(ModalCompletion   )completion;

@end
