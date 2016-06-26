//
//  GPXViewController.swift
//  Trax
//
//  Created by H Hugo Falkman on 2016-06-26.
//  Copyright © 2016 H Hugo Falkman. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Public Model
    
    var gpxURL: NSURL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url)  { gpx in
                    if gpx != nil {
                        self.addWaypoints(gpx!.waypoints)
                    }
                }
            }
        }
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }
    
    // MARK: Outlets

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .Satellite
            mapView.delegate = self
        }
    }
    
    // MARK: Private Implementation
    
    private func clearWaypoints() {
        mapView?.removeAnnotations(mapView.annotations)
    }
    
    private func addWaypoints(waypoints: [GPX.Waypoint]) {
        mapView?.addAnnotations(waypoints)
        mapView?.showAnnotations(waypoints, animated: true)
    }
    
    private func selectWaypoint(waypoint: GPX.Waypoint?) {
        if waypoint != nil {
            mapView.selectAnnotation(waypoint!, animated: true)
        }
    }
    
    // MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.draggable = annotation is EditableWaypoint
        
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if waypoint is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            }
        }
        
        return view
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton,
            let url = (view.annotation as? GPX.Waypoint)?.thumbnailURL,
            let imageData = NSData(contentsOfURL: url), // blocks main queue
            let image = UIImage(data: imageData) {
            thumbnailImageButton.setImage(image, forState: .Normal)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
        } else if control == view.rightCalloutAccessoryView {
            mapView.deselectAnnotation(view.annotation, animated: true)
            performSegueWithIdentifier(Constants.EditUserWaypoint, sender: view)
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController.contentViewController
        let annotationView = sender as? MKAnnotationView
        let waypoint = annotationView?.annotation as? GPX.Waypoint
        
        if segue.identifier == Constants.ShowImageSegue {
            if let ivc = destination as? ImageViewController {
                ivc.imageURL = waypoint?.imageURL
                ivc.title = waypoint?.name
            }
        } else if segue.identifier == Constants.EditUserWaypoint {
            if let editableWaypoint = waypoint as? EditableWaypoint,
                let ewvc = destination as? EditWaypointViewController {
                ewvc.waypointToEdit = editableWaypoint
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func addWaypoint(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            mapView.addAnnotation(waypoint)
            
        }
    }
    
    @IBAction func updatedUserWaypoint(segue: UIStoryboardSegue) {
        selectWaypoint((segue.sourceViewController.contentViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    // MARK: Constants
    
    private struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59) // sad face
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditUserWaypoint = "Edit Waypoint"
    }
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}

