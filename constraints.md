Mobile Position iOs constraints
===================
Goal: Record position of an iPhone / iPad


## Platform support

The app must support iOS 5.0+. Target is iPhone-only but developped as _Universal_ (iPad & iPhone). 
This does mean that there is no need to have a different layout for the iPad but it musn't be an iPhone only app that scales with the (2x) button. This is to be sure both viewPorts are considered from start.


## Offline support


- Limited, i.e. the app can run when no connection is available, but will be limited to data previously loaded; it will keep track of changes made while offline and sync them when connection is restored.


## Multiple languages

The user interface must be globalized (i.e. support multiple languages). 
(For information, the initial release is planned to be localized into: English and French)


## Code reuse

- Code must be properly componentized so that common functionality (at least basic interaction with the API) is written as a reusable library into an separate independant folder).
