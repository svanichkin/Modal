# Modal
The class allows without thinking about showing any controllers (modal / push) without thinking about the root controller.

Show controller immediately
```
[Modal showViewController:controller
                  options:kNilOptions
               completion:nil];
```  

Show controller after other
```
[Modal showViewController:controller
                  options:ModalOptionQuery
               completion:nil];
```  

Show controller immediately wrapped in navigation controller
```
[Modal showViewController:controller
                  options:ModalOptionNavigation
               completion:nil];
```  

Show controller immediately wrapped in navigation controller with hidden navigation bar
```
[Modal showViewController:controller
                  options:ModalOptionNavigation|ModalOptionNavigationHidden
               completion:nil];
```  

It is also possible to proxy clicks of view on the lower layers. For example, we need the window that is opened to be transparent for clicks (i.e., clicks are passed to the window below). To do this, it is sufficient to specify the proxyUserInteractionEnabled = YES parameter for the UIView. If you specify this key for the UIView, which is the lowest layer of the controller, the whole window will become transparent for clicks.

The controller can be obtained directly from the storyboard, just specify the name of the class with the Storyboard ID. For example, we have a class UIViewController on a storyboard and our class MyViewController is assigned to it, then in My Storiboard ID you also need to specify MyViewController. Then it will be possible to create controllers in this way:

```
MyViewController *controller = MyViewController.newFromStoryboard;
```  

You can also get a controller with a different name Storyboard ID, for example like this:
```
MyViewController *controller = [MyViewController newFromStoryboardWithId:@"Name"];
```  

And immediately show it like this:
```
[controller show];
```  

Or with the execution method at the end of the show:
```
[controller showWithCompletion:nil];

// or
[controller showWithOptions:kNilOptions
                 completion:nil];
```  

