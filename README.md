# RRGame
A rhythm reaction game for the UW Games Capstone course.

# Unit Testing
We are testing using munit, configured to support flixel
https://ashes999.github.io/learnhaxe/integration-testing-in-munit-with-haxeflixel.html

Basically, we use munit to manage our test suite (generate main and suite classes), but we run the tests through lime.

Installation:
1. install munit

Run Tests:
1. Navigate to test/
2. run command 'lime test neko' (html5 throws errors?)

Everything else:
1. run command 'haxelib run munit <command>'

# Manual Testing
The directory manual_test/ is for tests that cannot be verified programmatically (ie. painting)

Each folder in this directory is its own haxe flixel game that interfaces with the component under test.
As such, they each must contain a sym link to the original Project.xml in the root directory, the assets/ directory,
and the source/AssetPaths.hx haxe class. Its Main can then be edited to run a Test as a flixel game.

Create new test:
1. copy the new-test-template directory and change its CHANGEME hex class to a new test.

Run Test:
1. cd into the test directory (eg. manual_test/controls/)
2. run the game as normal ($ lime test html5).
