//
//  VELNSViewControllerTests.m
//  Velvet
//
//  Created by Justin Spahr-Summers on 19.02.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Velvet/Velvet.h>

@interface TestNSViewController : VELNSViewController
@property (nonatomic, weak) IBOutlet NSTextField *textField;

- (IBAction)doSomething:(id)sender;
@end

SpecBegin(VELNSViewController)
    
    it(@"should load an empty, zero-sized VELNSView", ^{
        VELNSViewController *controller = [[VELNSViewController alloc] init];
        expect(controller).not.toBeNil();
        expect(controller.viewLoaded).toBeFalsy();

        VELNSView *view = controller.view;
        expect(view).toBeKindOf([VELNSView class]);
        expect(CGRectIsEmpty(view.frame)).toBeTruthy();

        expect(view.guestView).not.toBeNil();
        expect(controller.guestView).toEqual(view.guestView);
        expect(CGRectIsEmpty(view.guestView.frame)).toBeTruthy();
    });

    describe(@"custom subclass", ^{
        it(@"should load view from nib", ^{
            TestNSViewController *controller = [[TestNSViewController alloc] init];
            expect(controller).not.toBeNil();
            expect(controller.viewLoaded).toBeFalsy();

            CGRect testNibFrame = CGRectMake(0, 0, 337, 210);

            VELNSView *view = controller.view;
            expect(view).not.toBeNil();
            expect(view.frame).toEqual(testNibFrame);

            expect(view.guestView).not.toBeNil();
            expect(view.guestView.frame).toEqual(testNibFrame);
            
            expect(controller.textField).not.toBeNil();
            expect(controller.textField.stringValue).toEqual(@"foobar");

            expect([controller.textField.cell action]).toEqual(@selector(doSomething:));
            expect([controller.textField.cell target]).toEqual(controller);
        });
    });

SpecEnd

@implementation TestNSViewController
@synthesize textField = m_textField;

- (NSString *)nibName {
    return @"testnib";
}

- (IBAction)doSomething:(id)sender {
}

@end
