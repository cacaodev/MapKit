// MKGeometry.j
// MapKit
//
// Created by Francisco Tolmasky.
// Copyright (c) 2010 280 North, Inc.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

MKWORLD_SIZE = 268435456;

function MKCoordinateSpan(/*CLLocationDegrees*/ aLatitudeDelta, /*CLLocationDegrees*/ aLongitudeDelta)
{
    this.latitudeDelta = aLatitudeDelta;
    this.longitudeDelta = aLongitudeDelta;

    return this;
}

MKCoordinateSpan.prototype.toString = function()
{
    return "{" + this.latitudeDelta + ", " + this.longitudeDelta + "}";
}

function MKCoordinateSpanMake(/*CLLocationDegrees*/ aLatitudeDelta, /*CLLocationDegrees*/ aLongitudeDelta)
{
    return new MKCoordinateSpan(aLatitudeDelta, aLongitudeDelta);
}

function MKCoordinateSpanFromLatLng(/*LatLng*/ aLatLng)
{
    return new MKCoordinateSpan(aLatLng.lat(), aLatLng.lng());
}

function CLLocationCoordinate2D(/*CLLocationDegrees*/ aLatitude, /*CLLocationDegrees*/ aLongitude)
{
    if (arguments.length === 1)
    {
        var coordinate = arguments[0];

        this.latitude = coordinate.latitude;
        this.longitude = coordinate.longitude;
    }
    else
    {
        this.latitude = +aLatitude || 0;
        this.longitude = +aLongitude || 0;
    }

    return this;
}

function CPStringFromCLLocationCoordinate2D(/*CLLocationCoordinate2D*/ aCoordinate)
{
    return "{" + aCoordinate.latitude + ", " + aCoordinate.longitude + "}";
}

function CLLocationCoordinate2DFromString(/*String*/ aString)
{
    var comma = aString.indexOf(',');

    return new CLLocationCoordinate2D(
        parseFloat(aString.substr(1, comma - 1)),
        parseFloat(aString.substring(comma + 1, aString.length)));
}

CLLocationCoordinate2D.prototype.toString = function()
{
    return CPStringFromCLLocationCoordinate2D(this);
}

function CLLocationCoordinate2DEqualToCLLocationCoordinate2D(/*CLLocationCoordinate2D*/ lhs, /*CLLocationCoordinate2D*/ rhs)
{
    return lhs === rhs || lhs.latitude === rhs.latitude && lhs.longitude === rhs.longitude;
}

function CLLocationCoordinate2DMake(/*CLLocationDegrees*/ aLatitude, /*CLLocationDegrees*/ aLongitude)
{
    return new CLLocationCoordinate2D(aLatitude, aLongitude);
}

function CLLocationCoordinate2DFromLatLng(/*LatLng*/ aLatLng)
{
    return new CLLocationCoordinate2D(aLatLng.lat(), aLatLng.lng());
}

function LatLngFromCLLocationCoordinate2D(/*CLLocationCoordinate2D*/ aLocation)
{
    return new google.maps.LatLng(aLocation.latitude, aLocation.longitude);
}

function MKCoordinateRegion(/*CLLocationCoordinate2D*/ aCenter, /*MKCoordinateSpan*/ aSpan)
{
    this.center = aCenter;
    this.span = aSpan;

    return this;
}

MKCoordinateRegion.prototype.toString = function()
{
    return "{" +
            this.center.latitude + ", " +
            this.center.longitude + ", " +
            this.span.latitudeDelta + ", " +
            this.span.longitudeDelta + "}";
}

function MKCoordinateRegionMake(/*CLLocationCoordinate2D*/ aCenter, /*MKCoordinateSpan*/ aSpan)
{
    return new MKCoordinateRegion(aCenter, aSpan);
}

function MKCoordinateRegionCopy(aRegion)
{
    var center = CLLocationCoordinate2DMake(aRegion.center.latitude, aRegion.center.longitude),
        span = MKCoordinateSpanMake(aRegion.span.latitudeDelta, aRegion.span.longitudeDelta);

    return MKCoordinateRegionMake(center, span);
}

function MKCoordinateRegionFromLatLngBounds(/*LatLngBounds*/ bounds)
{
    return new MKCoordinateRegion(
        CLLocationCoordinate2DFromLatLng(bounds.getCenter()),
        MKCoordinateSpanFromLatLng(bounds.toSpan()));
}

function LatLngBoundsFromMKCoordinateRegion(/*MKCoordinateRegion*/ aRegion)
{
    var latitude = aRegion.center.latitude,
        longitude = aRegion.center.longitude,
        latitudeDelta = aRegion.span.latitudeDelta,
        longitudeDelta = aRegion.span.longitudeDelta,
        LatLng = google.maps.LatLng,
        LatLngBounds = google.maps.LatLngBounds;

    return new LatLngBounds(
        new LatLng(latitude - latitudeDelta / 2, longitude - longitudeDelta / 2), // SW
        new LatLng(latitude + latitudeDelta / 2, longitude + longitudeDelta / 2) // NE
        );
}

function MKMapPoint(/* double*/ x, /*double*/ y)
{
	this.x = x;
    this.y = y;

    return this;
}

function MKMapPointMake(/* double*/ x, /*double*/ y)
{
	return new MKMapPoint(x,y);
}

function MKMapPointCopy(/*MKMapPoint*/ mapPoint)
{
	return new MKMapPoint(mapPoint.x, mapPoint.y);
}

function MKCoordinateForMapPoint(/*MKMapPoint*/ mapPoint)
{
    var projection = MKProjection();

    return projection.CoordinateForMapPoint(mapPoint);
}

function MKMapPointForCoordinate(/*CLLocationCoordinate2D*/ coordinate)
{
    var projection = MKProjection();

    return projection.MapPointForCoordinate(coordinate);
}

MKMapPoint.prototype.toString = function()
{
    return "{" +
            this.x + ", " +
            this.y + "}";
}

function MKMapSize(/* double*/ width, /*double*/ height)
{
	this.width = width;
    this.height = height;

    return this;
}

function MKMapSizeMake(/*double*/ width, /*double*/ height)
{
	return new MKMapSize(width, height);
}

function MKMapRect(/*MKMapPoint*/ origin, /*MKMapSize*/ size)
{
	this.origin = origin;
    this.size = size;

    return this;
}

function MKMapRectMake(/*double*/ x, /*double*/ y, /*double*/ width ,/*double*/ height)
{
	return new MKMapRect(MKMapPointMake(x, y), MKMapSizeMake(width, height));
}

function MKMapRectWorld()
{
    return MKMapRectMake(0, 0, MKWORLD_SIZE, MKWORLD_SIZE);
}

function MKMapRectZero()
{
    return MKMapRectMake(0, 0, 0, 0);
}

function MKMapRectGetMinX(aMapRect)
{
    return aMapRect.origin.x;
}

function MKMapRectGetMinY(aMapRect)
{
    return aMapRect.origin.y;
}

function MKMapRectGetWidth(aMapRect)
{
    return aMapRect.size.width;
}

function MKMapRectGetHeight(aMapRect)
{
    return aMapRect.size.height;
}

function MKMapRectGetMaxX(aMapRect)
{
    return aMapRect.origin.x + aMapRect.size.width;
}

function MKMapRectGetMaxY(aMapRect)
{
    return aMapRect.origin.y + aMapRect.size.height;
}

function MKMapRectGetMidX(aMapRect)
{
    return MKMapRectGetMinX(aMapRect) + MKMapRectGetWidth(aMapRect) / 2;
}

function MKMapRectGetMidY(aMapRect)
{
    return MKMapRectGetMinY(aMapRect) + MKMapRectGetHeight(aMapRect) / 2;
}

function MKMapRectContainsPoint(aMapRect, aMapPoint)
{
    return (aMapPoint.x >= aMapRect.origin.x &&
            aMapPoint.y >= aMapRect.origin.y &&
            aMapPoint.x < CGRectGetMaxX(aMapRect) &&
            aMapPoint.y < CGRectGetMaxY(aMapRect));
}

function MKMapRectIsEmpty(aMapRect)
{
    var size = aMapRect.size;
    return size.width === 0 && size.height === 0;
}

function MKMapRectForCoordinateRegion(region)
{
    var a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
        region.center.latitude + region.span.latitudeDelta / 2,
        region.center.longitude - region.span.longitudeDelta / 2));

    var b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
        region.center.latitude - region.span.latitudeDelta / 2,
        region.center.longitude + region.span.longitudeDelta / 2));

    return MKMapRectMake(MIN(a.x, b.x), MIN(a.y, b.y), ABS(a.x - b.x), ABS(a.y - b.y));
}

function MKMapRectIntersection(lhsRect, rhsRect)
{
    var intersection = MKMapRectMake(MAX(MKMapRectGetMinX(lhsRect), MKMapRectGetMinX(rhsRect)),
                                  MAX(MKMapRectGetMinY(lhsRect), MKMapRectGetMinY(rhsRect)),
                                  0, 0);

    intersection.size.width = MIN(MKMapRectGetMaxX(lhsRect), MKMapRectGetMaxX(rhsRect)) - MKMapRectGetMinX(intersection);
    intersection.size.height = MIN(MKMapRectGetMaxY(lhsRect), MKMapRectGetMaxY(rhsRect)) - MKMapRectGetMinY(intersection);

    return MKMapRectIsEmpty(intersection) ? MKMapRectZero() : intersection;
}

function MKMapRectIntersectsRect(lhsRect, rhsRect)
{
    var intersection = MKMapRectIntersection(lhsRect, rhsRect);

    return !MKMapRectIsEmpty(intersection);
}

function MKCoordinateRegionForMapRect(mapRect)
{
    var center = MKMapPointMake(MKMapRectGetMidX(mapRect), MKMapRectGetMidY(mapRect));

    var centerCoordinate = MKCoordinateForMapPoint(center);
    var originCoordinate = MKCoordinateForMapPoint(mapRect.origin);

    var span = MKCoordinateSpanMake(ABS(originCoordinate.latitude - centerCoordinate.latitude) *2 , ABS(centerCoordinate.longitude - originCoordinate.longitude) * 2);

    return MKCoordinateRegionMake(centerCoordinate, span);
}

MKMapRect.prototype.toString = function()
{
    return "{" +
            this.origin.x + ", " +
            this.origin.y + ", " +
            this.size.width + ", " +
            this.size.height + "}";
}

var MKProjection = function()
{
    if (typeof this.projection == 'undefined')
        this.projection = new MercatorProjection();

    return this.projection;
}

/** @constructor */
var MercatorProjection = function()
{
    this.pixelOrigin_ = MKMapPointMake(MKWORLD_SIZE / 2, MKWORLD_SIZE / 2);
    this.pixelsPerLonDegree_ = MKWORLD_SIZE / 360;
    this.pixelsPerLonRadian_ = MKWORLD_SIZE / (2 * PI);

    return this;
}

MercatorProjection.prototype.MapPointForCoordinate = function(coord)
{
    var me = this;
    var point = MKMapPointMake(0, 0);
    var origin = me.pixelOrigin_;

    point.x = origin.x + coord.longitude * me.pixelsPerLonDegree_;

    // Truncating to 0.9999 effectively limits latitude to 89.189. This is
    // about a third of a tile past the edge of the world tile.
    var siny = bound(SIN(degreesToRadians(coord.latitude)), -0.9999, 0.9999);
    point.y = origin.y + 0.5 * LOG((1 + siny) / (1 - siny)) * -me.pixelsPerLonRadian_;
    return point;
};

MercatorProjection.prototype.CoordinateForMapPoint = function(point)
{
    var me = this;
    var origin = me.pixelOrigin_;
    var lng = (point.x - origin.x) / me.pixelsPerLonDegree_;
    var latRadians = (point.y - origin.y) / -me.pixelsPerLonRadian_;
    var lat = radiansToDegrees(2 * ATAN(EXP(latRadians)) - PI / 2);

    return CLLocationCoordinate2DMake(lat, lng);
};

function bound(value, opt_min, opt_max)
{
    if (opt_min != null) value = MAX(value, opt_min);
    if (opt_max != null) value = MIN(value, opt_max);

    return value;
}

function degreesToRadians(deg)
{
    return deg * (PI / 180);
}

function radiansToDegrees(rad)
{
    return rad / (PI / 180);
}
