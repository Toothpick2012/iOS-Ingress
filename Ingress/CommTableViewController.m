//
//  CommTableViewController.m
//  Ingress
//
//  Created by Alex Studnicka on 10.01.13.
//  Copyright (c) 2013 A&A Code. All rights reserved.
//

#import "CommTableViewController.h"
#import "CommViewController.h"

#import "CommViewController.h"

@implementation CommTableViewController

@synthesize factionOnly = _factionOnly;

- (void)viewDidLoad {
    [super viewDidLoad];

	dateFormatter = [NSDateFormatter new];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];

//	if (![Utilities isOS7]) {
//		self.refreshControl = [UIRefreshControl new];
//		[self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
//	}

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

	self.fetchedResultsController = nil;
}

- (void)dealloc {
	self.fetchedResultsController = nil;
}

- (void)refresh {
//	[self.refreshControl beginRefreshing];
    
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:([self.tableView numberOfSections] - 1)] - 1) inSection:([self.tableView numberOfSections] - 1)];
    if (scrollIndexPath.row > -1) {
        [self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }

//	[Plext MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"factionOnly == %d", self.factionOnly]];

	[[API sharedInstance] loadCommunicationForFactionOnly:self.factionOnly completionHandler:^{
//		[self.refreshControl endRefreshing];

		self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"factionOnly == %d", self.factionOnly];
		[Plext MR_performFetch:self.fetchedResultsController];
        
        NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:([self.tableView numberOfSections] - 1)] - 1) inSection:([self.tableView numberOfSections] - 1)];
        if (scrollIndexPath.row > -1) {
            [self.tableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
	}];
}

- (void)setFactionOnly:(BOOL)factionOnly {
	if (factionOnly == _factionOnly) return;
	_factionOnly = factionOnly;
	[self refresh];
}

#pragma mark - NSFetchedResultsController & NSFetchedResultsControllerDelegate

- (NSFetchedResultsController *)fetchedResultsController {
	if (!_fetchedResultsController) {
		_fetchedResultsController = [Plext MR_fetchAllSortedBy:@"date" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"factionOnly == %d", self.factionOnly] groupBy:nil delegate:self];
	}
	return _fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
	return sectionInfo.numberOfObjects;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	Plext *plext = [self.fetchedResultsController objectAtIndexPath:indexPath];

	CGFloat width = tableView.frame.size.width;
	width -= 74;
	
	CGRect rect = [plext.message boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:NULL];
	
	return rect.size.height+1;
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	Plext *plext = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	CommTableViewCell *cell = (CommTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"msgCell" forIndexPath:indexPath];
	cell.timeLabel.font = [UIFont fontWithName:[[[UILabel appearance] font] fontName] size:10];
	cell.timeLabel.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:plext.date]];
	cell.messageLabel.attributedText = plext.message;
	cell.mentionsYou = plext.mentionsYou;
	return cell;
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Player *player = [[API sharedInstance] playerForContext:[NSManagedObjectContext MR_contextForCurrentThread]];
	Plext *plext = [self.fetchedResultsController objectAtIndexPath:indexPath];
	User *sender = plext.sender;

	if (sender && ![sender.guid isEqualToString:player.guid]) {
		CommViewController *commVC = (CommViewController *)self.parentViewController.parentViewController;
		[commVC mentionUser:plext.sender];
	}
}

@end
