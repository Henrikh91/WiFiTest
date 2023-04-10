//
//  ViewController.m
//  TestWiFi
//
//  Created by Genrih Korenujenko on 13.11.17.
//  Copyright © 2017 Koreniuzhenko Henrikh. All rights reserved.
//

#import "ViewController.h"
#import "NICInfoSummary.h"
#import "TableCell.h"

static const NSInteger UNSELECTED_INDEX = -1;

@interface ViewController () <NSTableViewDataSource, NSTableViewDelegate>
{
    __weak IBOutlet NSTableView *table;
    NSMutableArray *items;
    NSInteger selectedIndex;
}
@end

@implementation ViewController

#pragma mark - Override Methods
-(void)viewDidLoad
{
    [super viewDidLoad];
//    selectedIndex = UNSELECTED_INDEX;
//    NICInfoSummary *summary = [[NICInfoSummary alloc] init];
//    items = [NSMutableArray arrayWithArray:summary.nicInfos];
//    
//    table.target = self;
//    table.action = @selector(tableViewDidClick);
//    [table reloadData];
}

#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    if (tableView.tag == 1 && tableView.clickedRow >= 0)
        return [self getIPInfos].count;
    else
        return items.count;
}

-(NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:nil];

    if (tableView.tag == 1)
    {
        NICIPInfo *ipInfo = [self getIPInfoAtIndex:row];
        if ([tableColumn.identifier isEqualToString:@"ip"])
            cell.textField.stringValue = ipInfo.ip;
    }
    else
    {
        NICInfo *info = items[row];
        
        if ([tableColumn.identifier isEqualToString:@"interface"])
            cell.textField.stringValue = info.interfaceName;
        else if ([tableColumn.identifier isEqualToString:@"mac_address"])
            cell.textField.stringValue = info.macAddress;
    }
    
    return cell;
}

-(void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor*>*)oldDescriptors
{
    if (tableView.tag == 2)
    {
        [items sortUsingDescriptors:tableView.sortDescriptors];
        [tableView reloadData];
    }
}

- (void)tableViewDidClick
{
    if (table.clickedRow >= 0)
    {
        NSInteger row = table.clickedRow;
        NSTableColumn *tableColumn = [table tableColumnWithIdentifier:@"ips"];
        
        if (table.clickedRow == selectedIndex)
        {
            selectedIndex = UNSELECTED_INDEX;
            tableColumn.hidden = YES;
        }
        else
        {
            selectedIndex = row;
            tableColumn.hidden = NO;
        }
        
        TableCell *cell = [table makeViewWithIdentifier:tableColumn.identifier owner:nil];
        cell.ipsTableView.tag = 1;
        [cell.ipsTableView reloadData];
    }
}

#pragma mark - Private Methods
-(NSArray<NICIPInfo*>*)getIPInfos
{
    return [items[selectedIndex] nicIPInfos];
}

-(NICIPInfo*)getIPInfoAtIndex:(NSInteger)index
{
    return [self getIPInfos][index];
}

@end
