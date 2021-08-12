//
//  Modal.h
//  v.2.4.2
//
//  Created by Сергей Ваничкин on 12/3/18.
//  Copyright © 2018 Macflash. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
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
//  [Modal showViewController:controller
//                    options:kNilOptions
//                 completion:nil];
//
//  Показать контроллер, через очередь
//
//  [Modal showViewController:controller
//                    options:ModalOptionQuery
//                 completion:nil];
//
//  Показать контроллер немендленно, обернутый в контроллер навигации
//
//  [Modal showViewController:controller
//                    options:ModalOptionNavigation
//                 completion:nil];
//
//  Показать контроллер немендленно, обернутый в контроллер навигации, со скрытым меню
//
//  [Modal showViewController:controller
//                    options:ModalOptionNavigation|ModalOptionNavigationHidden
//                 completion:nil];
//
//  Также есть возможность проксировать нажатия view на нижние слои. Например
//  нам нужно что бы окно которое сейачс открыто было прозрачным для нажатий
//  (т.е. нажатия передавались окну которое ниже). Для этого достаточчно указать
//  для UIView параметр proxyUserInteractionEnabled = YES.
//  Если указать этот ключ для UIView являющегося самым нижним слоем контроллера
//  то все окно станет прозрачным для нажатий.
//
//  Контоллер можно получить прямо из сторибоарда, достаточно указать Storyboard ID
//  название класса. Например у нас в есть класс UIViewController на сторибораде и ему
//  назначен наш класс MyViewController, тогда в Storiboard ID так же нужно указать
//  MyViewController. Тогда можно будет создавать контроллеры таким образом:
//
//  MyViewController *controller = MyViewController.newFromStoryboard;
//
//  Также можно получить контроллер и с другим названием Storyboard ID, например так:
//
//  MyViewController *controller = [MyViewController newFromStoryboardWithId:@"Name"];
//
//  И сразу показать его так:
//
//  [controller show];
//
//  Либо с методом выполнения по окончании показа:
//
//  [controller showWithCompletion:nil];
//
//  [controller showWithOptions:kNilOptions
//                   completion:nil];
//

#import <UIKit/UIKit.h>

typedef enum
{
    ModalOptionNone                      = 0,
    ModalOptionNoAnimated                = 1 << 0,
    ModalOptionQuery                     = 1 << 1,
    ModalOptionNavigation                = 1 << 2,
    ModalOptionNavigationHidden          = 1 << 3,
    ModalOptionAlwaysOnTop               = 1 << 4,
} ModalOptions;

typedef void(^ModalCompletion)(void);

@interface Modal : NSObject

+(void)showViewController:(UIViewController  *)viewController
                  options:(ModalOptions       )options
               completion:(ModalCompletion    )completion;

@end

@interface UIView (ProxyUserInteraction)

@property (nonatomic, assign) IBInspectable BOOL proxyUserInteractionEnabled;

@end

@interface UIViewController (Storyboard)

+(instancetype)newFromStoryboard;
+(instancetype)newFromStoryboardWithId:(NSString *)storyboardId;

-(void)show;
-(void)showCompletion:(ModalCompletion)completion;
-(void)showWithOptions:(ModalOptions   )options
            completion:(ModalCompletion)completion;

@end
