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
