# Modal
The class allows without thinking about showing any controllers (modal / push) without thinking about the root controller.

Show controller immediately
```
[Modal.current showViewController:controller
                          options:kNilOptions
                       completion:nil];
```  

Show controller after other
```
[Modal.current showViewController:controller
                          options:ModalOptionQuery
                       completion:nil];
```  

Show controller immediately wrapped in navigation controller
```
[Modal.current showViewController:controller
                          options:ModalOptionNavigation
                       completion:nil];
```  

Show controller immediately wrapped in navigation controller with hidden navigation bar
```
[Modal.current showViewController:controller
                          options:ModalOptionNavigation|ModalOptionNavigationHidden
                       completion:nil];
```  

It is also possible to proxy click view on the lower layers. For example, we need the window to open transparently to clicks (i.e. the clicks are passed to the window below). For this, it is sufficient to specify the proxyUserInteractionEnabled = YES parameter for UIView. If you specify this key for UIView, which is the lowest layer of the controller, then the entire window will become transparent for clicks.
