//
//  AIRUrlTileOverlay.m
//  AirMaps
//
//  Created by cascadian on 3/19/16.
//  Copyright © 2016. All rights reserved.
//

#import "AIRMapUrlTile.h"
#import <React/UIView+React.h>

@interface Coordinate:NSObject
@property double lat;
@property double lon;
@end
@implementation Coordinate
@end

@interface Coordtransform:NSObject
@end

@implementation Coordtransform
double a = 6378245.0;
double ee = 0.00669342162296594323;

+(Coordinate *)wgs84togcj02:(double)wgLat wgLon:(double)wgLon{
    Coordinate *coord = [[Coordinate alloc]init];
    if([Coordtransform outOfChina:wgLat lon:wgLon]){
        [coord setLat:wgLat];
        [coord setLon:wgLon];
        return coord;
    }
    double dLat = [Coordtransform transformLat:wgLon - 105.0 y:wgLat - 35.0];
    double dLon = [Coordtransform transformLon:wgLon - 105.0 y:wgLat - 35.0];
    double radLat = wgLat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0 ) / (( a * ( 1 - ee )) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0 ) / (a/sqrtMagic * cos(radLat) * M_PI);
    [coord setLat:wgLat + dLat];
    [coord setLon:wgLon + dLon];
    return coord;
    //    var dLon:Double = transformLon(x:wgLon - 105.0, y:wgLat - 35.0);
    //    let radLat:Double = wgLat / 180.0 * Double.pi;
    //    var magic:Double = sin(radLat);
    //    magic = 1 - ee * magic * magic;
    //    let sqrtMagic:Double = sqrt(magic);
    //    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi);
    //    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi);
    //    mgLat = wgLat + dLat;
    //    mgLon = wgLon + dLon;
}
+(BOOL)outOfChina:(double)lat lon:(double)lon{
    //    if lon < 72.004 || lon > 137.8347{
    //        return true;
    //    }
    //    if lat < 0.8293 || lat > 55.8271{
    //        return true;
    //    }
    //    return false;
    if( lon < 72.004 || lon > 137.8347 ){
        return YES;
    }
    if( lat < 0.8293 || lat > 55.8271){
        return YES;
    }
    return NO;
}
+(double)transformLat:(double)x y:(double)y{
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}
+(double)transformLon:(double)x y:(double)y{
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}
@end

@interface WGC84TileTransform:NSObject
@end

@implementation WGC84TileTransform
double tileSize = 256;
double initialresolution = 156543.03392804062;
double originShift = 20037508.342789244;

-(double)pixels2Meters:(double)p zoom:(double)zoom{
    return p * [self resolution:zoom] - originShift;
}

/**
 计算分辨率
 
 @param zoom
 @return
 */
-(double)resolution:(double)zoom{
    return initialresolution / pow(2, zoom);
}

/**
 X米转经纬度
 
 @param mx
 @return
 */
-(double)meters2Lon:(double)my{
    return (my / originShift ) * 180.0;
}


/**
 Y米转经纬度
 
 @param my
 @return
 */
-(double)meters2Lat:(double)my{
    double lat = ( my / originShift ) * 180.0;
    return 180.0 / M_PI * ( 2 * atan(exp(lat * M_PI / 180.0)) - M_PI / 2.0);
}


/**
 X经纬度转米
 
 @param lon
 @return
 */
-(double)lon2Meter:(double)lon{
    return lon * originShift / 180.0;
}

/**
 Y经纬度转米
 
 @param lat
 @return
 */
-(double)lat2Meter:(double)lat{
    double my = log(tan((90 + lat) * M_PI / 360.0)) / (M_PI / 180.0);
    my = my * originShift / 180.0;
    return my;
}

-(NSString *)tileBounds:(double)tx ty:(double)ty zoom:(double)zoom{
    double minX = [self pixels2Meters:tx * tileSize zoom:zoom];
    double maxY = -[self pixels2Meters:ty * tileSize zoom:zoom];
    double maxX = [self pixels2Meters:(tx + 1) * tileSize zoom:zoom];
    double minY = -[self pixels2Meters:(ty + 1) * tileSize zoom:zoom];
    minX = [self meters2Lon:minX];
    minY = [self meters2Lat:minY];
    maxX = [self meters2Lon:maxX];
    maxY = [self meters2Lat:maxY];
    //    double *minLat = 0;
    //    double *minLon = 0;
    //    double *maxLat = 0;
    //    double *maxLon = 0;
    Coordinate *minCoord = [Coordtransform wgs84togcj02:minX wgLon:minY];
    Coordinate *maxCoord = [Coordtransform wgs84togcj02:maxX wgLon:maxY];
    
    NSArray *arr = [NSArray arrayWithObjects:[[NSNumber numberWithDouble:[minCoord lat]] stringValue], [[NSNumber numberWithDouble:[minCoord lon]] stringValue], [[NSNumber numberWithDouble:[maxCoord lat]] stringValue], [[NSNumber numberWithDouble:[maxCoord lon]] stringValue], nil];
    return [[arr componentsJoinedByString:@","] stringByAppendingString:@"&WIDTH=256&HEIGHT=256"];
}
@end

@interface FlightTileOverlay:MKTileOverlay
@end

@implementation FlightTileOverlay

- (NSURL *)URLForTilePath:(MKTileOverlayPath)path{
    WGC84TileTransform *wgc84Coord = [[WGC84TileTransform alloc] init];
    NSString *coordStr = [wgc84Coord tileBounds:path.x ty:path.y zoom:path.z];
    wgc84Coord = nil;
    NSString *newUrlTemplate = self.URLTemplate;
    //    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+\\.\\d+,)+\\d+\\.\\d+\\&width=\\d+\\&height=\\d+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:newUrlTemplate options:0 range:NSMakeRange(0, [newUrlTemplate length]) withTemplate:coordStr];
    //    let wgc84Coord:WGC84TileTransform = WGC84TileTransform()
    //    let coordStr:String = wgc84Coord.tileBounds(tx: Double(path.x), ty: Double(path.y), zoom: Double(path.z))
    //    var newUrlTemplate = self.urlTemplate!
    //    let range = newUrlTemplate.range(of: "(\\d+\\.\\d+,)+\\d+\\.\\d+\\&width=\\d+\\&height=\\d+", options: .regularExpression, range: newUrlTemplate.startIndex..<newUrlTemplate.endIndex, locale: Locale.current)
    //    newUrlTemplate.replaceSubrange(range!, with: "\(coordStr)&WIDTH=256&HEIGHT=256")
    //    return URL.init(string: newUrlTemplate)!
    //    NSLog(@"%@",modifiedString);
    NSString *urlStr = modifiedString;
    NSURL *url = [[NSURL alloc] initWithString:urlStr];
    return url;
}
@end

@implementation AIRMapUrlTile {
    BOOL _urlTemplateSet;
}


- (void)setUrlTemplate:(NSString*)urlTemplate{
    _urlTemplate = urlTemplate;
    _urlTemplateSet = YES;
    [self createTileOverlayAndRendererIfPossible];
    [self update];
}

- (void) createTileOverlayAndRendererIfPossible
{
    if (!_urlTemplateSet) return;
    //    self.tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:self.urlTemplate];
    self.tileOverlay = nil;
    self.tileOverlay = [[FlightTileOverlay alloc] initWithURLTemplate:self.urlTemplate];
    //    self.tileOverlay.canReplaceMapContent = YES;
    //    self.tileOverlay.canReplaceMapContent = NO;
    self.tileOverlay.minimumZ = 0;
    self.tileOverlay.maximumZ = 20;
    self.tileOverlay.tileSize = CGSizeMake(256, 256);
    if (self.maximumZ) {
        self.tileOverlay.maximumZ = self.maximumZ;
    }
    self.renderer = nil;
    self.renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:self.tileOverlay];
    self.renderer.alpha = 1;
    //    for( int i = 0; i < self.urlTemplate.count; i++){
    //        FlightTileOverlay *tileOverlay = [[FlightTileOverlay alloc] initWithURLTemplate: [ self.urlTemplate objectAtIndex:i ] ];
    //        tileOverlay.minimumZ = 0;
    //        tileOverlay.maximumZ = 20;
    //        tileOverlay.tileSize = CGSizeMake(256, 256);
    //        [self.tileOverlay arrayByAddingObject:tileOverlay];
    //        MKTileOverlayRenderer *renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:tileOverlay];
    //        renderer.alpha = 1;
    //        [self.renderer arrayByAddingObject:renderer];
    //    }
}

- (void) update
{
    if (!_renderer) return;
    
    if (_map == nil) return;
    [_map removeOverlay:self];
    [_map addOverlay:self];
    //    [_map addOverlay:self];
}

#pragma mark MKOverlay implementation

- (CLLocationCoordinate2D) coordinate
{
    return self.tileOverlay.coordinate;
}

- (MKMapRect) boundingMapRect
{
    return self.tileOverlay.boundingMapRect;
}

- (BOOL)canReplaceMapContent
{
    return self.tileOverlay.canReplaceMapContent;
}

@end
