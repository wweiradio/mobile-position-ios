//
//  Logging.h
//  AT PrYv
//
//  Created by Konstantin Dorodov on 4/11/13.
//  Copyright (c) 2013 PrYv. All rights reserved.
//

#ifndef AT_PrYv_Logging_h
#define AT_PrYv_Logging_h

#import "DDLog.h"

// lumberjack logging
#if DEBUG
  static const int ddLogLevel = LOG_LEVEL_VERBOSE;
  #define NSLog DDLogVerbose
#else
  static const int ddLogLevel = LOG_LEVEL_INFO;
  #define NSLog DDLogInfo
#endif

#endif
