#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(5);

captureLocalizedScreenshot("0-FirstScreen")

app.tabBar().buttons()["Schedule"].tap();
app.statusBar().tapWithOptions({tapOffset:{x:0.62, y:0.62}});

captureLocalizedScreenshot("1-SecondScreen")

// target.lockForDuration(0)

// captureLocalizedScreenshot("2-ThirdScreen")