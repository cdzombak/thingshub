/*
 * Things.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class ThingsWindow, ThingsApplication, ThingsList, ThingsArea, ThingsContact, ThingsTag, ThingsToDo, ThingsProject, ThingsSelectedToDo;

enum ThingsPrintingErrorHandling {
    ThingsPrintingErrorHandlingStandard = 'lwst' /* Standard PostScript error handling */,
    ThingsPrintingErrorHandlingDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum ThingsPrintingErrorHandling ThingsPrintingErrorHandling;

enum ThingsStatus {
    ThingsStatusOpen = 'tdio' /* To do is open. */,
    ThingsStatusCompleted = 'tdcm' /* To do has been completed. */,
    ThingsStatusCanceled = 'tdcl' /* To do has been canceled. */
};
typedef enum ThingsStatus ThingsStatus;

@protocol ThingsGenericMethods

- (void) close;  // Close a window.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (void) show;  // Show Things item in the UI
- (void) moveTo:(ThingsList *)to;  // Move a to do to a different list.
- (void) scheduleFor:(NSDate *)for_;  // Schedules a Things to do

@end



/*
 * Standard Suite
 */

// A window.
@interface ThingsWindow : SBObject <ThingsGenericMethods>

@property (copy, readonly) NSString *name;  // The full title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (readonly) BOOL minimizable;  // Whether the window can be minimized.
@property BOOL minimized;  // Whether the window is currently minimized.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.


@end



/*
 * Things Suite
 */

// The application's top-level scripting object.
@interface ThingsApplication : SBApplication

- (SBElementArray<ThingsWindow *> *) windows;
- (SBElementArray<ThingsList *> *) lists;
- (SBElementArray<ThingsToDo *> *) toDos;
- (SBElementArray<ThingsProject *> *) projects;
- (SBElementArray<ThingsArea *> *) areas;
- (SBElementArray<ThingsContact *> *) contacts;
- (SBElementArray<ThingsTag *> *) tags;
- (SBElementArray<ThingsSelectedToDo *> *) selectedToDos;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *version;  // The version of the application.

- (void) print:(id)x withProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) quit;  // Quit the application.
- (BOOL) exists:(id)x;  // Verify if an object exists.
- (void) showQuickEntryPanelWithAutofill:(BOOL)withAutofill withProperties:(NSDictionary *)withProperties;  // Show Things Quick Entry panel
- (void) logCompletedNow;  // Log completed items now
- (void) emptyTrash;  // Empty Things trash
- (ThingsContact *) addContactNamed:(NSString *)x;  // Add a contact to Things from your Address Book
- (ThingsToDo *) parseQuicksilverInput:(NSString *)x;  // Add new Things to do from input in Quicksilver syntax

@end

// Represents a Things list.
@interface ThingsList : SBObject <ThingsGenericMethods>

- (SBElementArray<ThingsToDo *> *) toDos;

- (NSString *) id;  // The unique identifier of the list.
@property (copy) NSString *name;  // Name of the list


@end

// Represents a Things area of responsibility.
@interface ThingsArea : ThingsList

- (SBElementArray<ThingsToDo *> *) toDos;
- (SBElementArray<ThingsTag *> *) tags;

@property (copy) NSString *tagNames;  // Tag names separated by comma
@property BOOL collapsed;  // Is this area collapsed?


@end

// Represents a Things contact.
@interface ThingsContact : ThingsList

- (SBElementArray<ThingsToDo *> *) toDos;


@end

// Represents a Things tag.
@interface ThingsTag : SBObject <ThingsGenericMethods>

- (SBElementArray<ThingsTag *> *) tags;
- (SBElementArray<ThingsToDo *> *) toDos;

- (NSString *) id;  // The unique identifier of the tag.
@property (copy) NSString *name;  // Name of the tag
@property (copy) NSString *keyboardShortcut;  // Keyboard shortcut for the tag
@property (copy) ThingsTag *parentTag;  // Parent tag


@end

// Represents a Things to do.
@interface ThingsToDo : SBObject <ThingsGenericMethods>

- (SBElementArray<ThingsTag *> *) tags;

- (NSString *) id;  // The unique identifier of the to do.
@property (copy) NSString *name;  // Name of the to do
@property (copy) NSDate *creationDate;  // Creation date of the to do
@property (copy) NSDate *modificationDate;  // Modification date of the to do
@property (copy) NSDate *dueDate;  // Due date of the to do
@property (copy, readonly) NSDate *activationDate;  // Activation date of the scheduled to do
@property (copy) NSDate *completionDate;  // Completion date of the to do
@property (copy) NSDate *cancellationDate;  // Cancellation date of the to do
@property ThingsStatus status;  // Status of the to do
@property (copy) NSString *tagNames;  // Tag names separated by comma
@property (copy) NSString *notes;  // Notes of the to do
@property (copy) ThingsProject *project;  // Project the to do belongs to
@property (copy) ThingsArea *area;  // Area the to do belongs to
@property (copy) ThingsContact *contact;  // Contact the to do is assigned to

- (void) edit;  // Edit Things to do

@end

// Represents a Things project.
@interface ThingsProject : ThingsToDo

- (SBElementArray<ThingsToDo *> *) toDos;


@end

// Represents a to do selected in Things UI.
@interface ThingsSelectedToDo : ThingsToDo


@end

