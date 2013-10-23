//
//  HLSInMemoryFileManager.h
//  CoconutKit
//
//  Created by Samuel Défago on 18.10.13.
//  Copyright (c) 2013 Hortis. All rights reserved.
//

#import "HLSFileManager.h"

/**
 * A file manager implementation storing data in memory
 */
@interface HLSInMemoryFileManager : HLSFileManager <NSCacheDelegate>

/**
 * Size of the data cache, in bytes, above which the cache might be cleaned (refer to the -[NSCache setTotalCostLimit:] 
 * method documentation for more information). When data is added to the cache, its size in bytes is used as cost
 *
 * Default value is 0 (no limit)
 */
@property (nonatomic, assign) NSUInteger byteCostLimit;

@end
