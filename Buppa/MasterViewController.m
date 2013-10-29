//
//  MasterViewController.m
//  Buppa
//
//  Created by 大坪裕樹 on 2013/10/15.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"

@interface MasterViewController () {
    
}
@end

@implementation MasterViewController {
    // OAuth認証オブジェクト
    GTMOAuthAuthentication *auth_;
    // 表示中ツイート情報
    NSArray *timelineStatuses_;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
}

// KeyChain登録サービス名
static NSString *const kKeychainAppServiceName = @"KodawariButter";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // GTMOAuthAuthenticationインスタンス生成
    // ※自分の登録アプリの Consumer Key と Consumer Secret に書き換えてください
    NSString *consumerKey = @"ggs4QYc74zcujjjuhZvU6A";
    NSString *consumerSecret = @"vzFAwV6Mvu9KSGfjyTxATmXPqhmgn6FptI1TdI2Va0";
    auth_ = [[GTMOAuthAuthentication alloc]
             initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
             consumerKey:consumerKey
             privateKey:consumerSecret];
    
    //すでにOAuth認証済みなら、KeyChainから認証情報を読み込む
    BOOL authorized = [GTMOAuthViewControllerTouch
                       authorizeFromKeychainForName:kKeychainAppServiceName
                       authentication:auth_];
    if  (authorized) {
        //認証済みの場合はタイムライン更新
        [self asyncShowHomeTimeline];
    } else {
        //未認証の場合は認証処理を実施
        [self asyncSignIn];
    }
}
// 認証処理
- (void)asyncSignIn
{
    NSString *requestTokenURL = @"https://api.twitter.com/oauth/request_token";
    NSString *accessTokenURL = @"https://api.twitter.com/oauth/access_token";
    NSString *authorizeURL = @"https://api.twitter.com/oauth/authorize";
    
    NSString *keychainAppServiceName = @"KodawariButter";
    
    auth_.serviceProvider = @"Twitter";
    auth_.callback = @"http://www.example.com/OAuthCallback";
    
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[GTMOAuthViewControllerTouch alloc]
                      initWithScope:nil
                      language:nil
                      requestTokenURL:[NSURL URLWithString:requestTokenURL]
                      authorizeTokenURL:[NSURL URLWithString:authorizeURL]
                      accessTokenURL:[NSURL URLWithString:accessTokenURL]
                      authentication:auth_
                      appServiceName:keychainAppServiceName
                      delegate:self
                      finishedSelector:@selector(authViewContoller:finishWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

// 認証エラー表示AlertViewタグ
static const int kMyAlertViewTagAuthenticationError = 1;

// 認証処理が完了した場合の処理
- (void)authViewContoller:(GTMOAuthViewControllerTouch *)viewContoller
           finishWithAuth:(GTMOAuthAuthentication *)auth
                    error:(NSError *)error
{
    if (error != nil) {
        // 認証失敗
        NSLog(@"Authentication error: %d.", error.code);
        UIAlertView *alertView;
        alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Authentication failed."
                                              delegate:self
                                     cancelButtonTitle:@"Confirm"
                                     otherButtonTitles:nil];
        alertView.tag = kMyAlertViewTagAuthenticationError;
        [alertView show];
    } else {
        // 認証成功
        NSLog(@"Authentication succeeded.");
        // タイムライン表示
        [self asyncShowHomeTimeline];
    }
}

// UIAlertViewが閉じられた時
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 認証失敗通知AlertViewが閉じられた場合
    if (alertView.tag == kMyAlertViewTagAuthenticationError) {
        // 再度認証
        [self asyncSignIn];
    }
}

// デフォルトのタイムライン処理表示
- (void)asyncShowHomeTimeline
{
    [self fetchGetHomeTimeline];
}

// タイムライン (home_timeline) 取得
- (void)fetchGetHomeTimeline
{
    // 要求を準備
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 非同期通信による取得開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(homeTimelineFetcher:finishedWithData:error:)];
}

// タイムライン (home_timeline) 取得応答時
- (void)homeTimelineFetcher:(GTMHTTPFetcher *)fetcher
           finishedWithData:(NSData *)data
                      error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&jsonError];
    
    // JSONデータのパースエラー
    if (statuses == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    timelineStatuses_ = statuses;
    
    // テーブルを更新
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
*/

#pragma mark - Table View

// テーブルのセクション数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// テーブルの行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [timelineStatuses_ count];
}

// 指定位置に挿入されるセルの要求
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文を表示
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.text = [status objectForKey:@"text"];
    
    // ユーザ情報から screen_name を取り出して表示
    NSDictionary *user = [status objectForKey:@"user"];
    cell.detailTextLabel.text = [user objectForKey:@"screen_name"];
    
    return cell;
}

// 指定位置の行で使用する高さの要求
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文をもとにセルの高さを決定
    NSString *content = [status objectForKey:@"text"];
    NSDictionary *stringAttributes = [ NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:12] forKey:NSFontAttributeName];
    CGRect labelSize = [content boundingRectWithSize:CGSizeMake(300, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:stringAttributes context:nil];
    
    return labelSize.size.height + 25;
}


/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}
*/

@end
