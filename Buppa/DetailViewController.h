//
//  DetailViewController.h
//  Buppa
//
//  Created by 大坪裕樹 on 2013/10/15.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
