# Kitchen Utensils 

![Screen Recording](https://github.com/user-attachments/assets/dfc890e5-b5ba-42b2-8999-0bbca98af1f2)

Kitchen Utensils is an iOS app built using Swift, SwiftUI, and SwiftData. It supports Swift 6, Xcode/iOS 26, and Swift Testing for unit tests.

The main ContentView will contain a scrolling list of Utensils, called UtensilListView, wrapped in a NavigationStack (or NavigationSplitView if we need iPad support), with a navigation title of “Kitchen Utensils”.

Each Utensil will consist of a name and photo, as well as an id of type UUID for Identifiable conformance, and a creationDate that's generated at time of creation.

The user will start from an empty list and will be able to add Utensils. We'll use a ContentUnavailableView for the empty state. 

In the navigation bar trailing position should be a Plus icon, which tapping opens a sheet in which the user can enter a new Utensil, called AddUtensilView. There will be a TextField to enter a name, and a Choose Photo button to present the system PhotosPicker, allowing the user to select a photo from the device Photos library. Once a photo is selected, a preview will show inline, above the Choose Photo button. We'll have to add a usage description string for access to the user's photo library in the Info.plist. There should be a Save button in the navigation bar trailing position, which is disabled until both name and photo are populated and valid. Name should be no more than 100 characters, and can contain letters, numbers, spaces, special characters, and emoji, but no line breaks - white space at the start and end should be stripped. 

To Save the Utensil, we'll use a combination of CoreData and local file store. Upon tapping Save from within AddUtensilView, we should generate a UUID, then attempt to store the photo in the Application Support folder, in the `originals` subdirectory, with the filename being the UUID string representation and the extension matching the original file. Once that succeeds, we should make a thumbnail image by cropping the image to a square aspect ratio, and then scaling it down to 180 pixels wide - this thumbnail image should then be saved to the Application Support folder, in a the `thumbnails` subdirectory, with the filename being the UUID string representation and extension being jpeg. Last, if those two file save operations succeed, we should save the Utensil object to a SwiftData persistent store, with the id being the UUID, along with name and creation date. If the SwiftData save fails, we should delete the two files, making the entire save operation atomic. If any of the save operations fail, we should present an alert "Sorry, something went wrong" with an accompanying error localizedDescription. If the whole operation fully succeeds, we should dismiss AddUtensilView.    

Inside UtensilListView will be an @Query to return an array of Utensils, which a ForEach statement will iterate over, inflating each one into a UtensilCellView. Each UtensilCellView will contain the name and a small (60pt, square) thumbnail version of the photo. If no thumbnail image is found, we'll fallback to a suitable SF Image icon as a placeholder. It's out of scope, but swiping on a UtensilCellView should activate the built in behavior for deleting the Utensil. Also out of scope: tapping on a UtensilCellView should navigate to a UtensilDetailView, which will show the name, creationDate, and a larger version of the image.

Architecturally, we should have an ImageRepository actor that exposes the following functions: add(image: URL, named: String) throws, thumbnail(for:) -> UIImage?, and original(for:) -> UIImage?. Internally, it should utilize an NSCache to hold the thumbnails in memory, so that we don't have to continually load them from disk.

We'll build the project incrementally, in the following order:

- Create a new git repo
- Add README and .gitignore
- Create a new KitchenUtensils Project in Xcode, using the App template, utilizing Swift, SwiftUI, SwiftData, and Swift Testing... this will give us the KitchenUtensilsApp.swift entry point, ContentView.swift base view, and Item.swift SwiftData object, with a modelContext @Environment object
- Rename Item.swift to Utensil.swift: SwiftData model object with properties for id (UUID), name (String), extension (String), and creationDate (Date)
- UtensilListView.swift, which also includes UtensilCellView, making sure the Preview works with placeholder data. To start with, do not include the swipe to delete feature or tap to view detail feature.
- ImageRepository.swift for handling image storage and retrieval
- AddUtensilView.swift for saving new utensils, along with usage description string
- Add App Icon
- Add screenshots and video evidence

With remaining time:

- Add swipe to delete to UtensilListView
- Add appropriate unit tests and UI tests
- Add UtensilDetailView.swift and ability to navigate to it from UtensilListView by tapping the corresponding UtensilCellView

