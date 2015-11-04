//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
import UIKit
import Metal
import QuartzCore
//------------------------------------------------------------------------------
// View Controller for Metal Sample Code. Maintains a CADisplayLink
// timer that runs on the main thread and triggers rendering in AAPLView.
// Provides update callbacks to its delegate on the timer, prior to triggering rendering.
//------------------------------------------------------------------------------
// required view controller delegate functions.
//------------------------------------------------------
@objc protocol TViewControllerDelegate
{
    //------------------------------------------------------
    // Note this method is called from the
    // thread the main game loop is run
    //------------------------------------------------------
    func update(controller:TViewController)

    //------------------------------------------------------
    // called whenever the main game loop is paused,
    // such as when the app is backgrounded
    //------------------------------------------------------
    func viewController(controller:TViewController, willPause:Bool)
}
//------------------------------------------------------------------------------
class TViewController: UIViewController
{
    @IBOutlet weak var delegate: TViewControllerDelegate!
   
    //------------------------------------------------------
    // What vsync refresh interval to fire at.
    // (Sets CADisplayLink frameinterval property)
    // set to 1 by default, which is the CADisplayLink
    // default setting (60 FPS).
    // Setting to 2, will cause gameloop to trigger
    // every other vsync (throttling to 30 FPS)
    //------------------------------------------------------
    var interval:Int = 1
    
    //------------------------------------------------------
    // View Controller for Metal Sample Code. Maintains
    // a CADisplayLink timer that runs on the main thread and
    // triggers rendering in AAPLView.
    // Provides update callbacks to its delegate on the timer,
    // prior to triggering rendering.
    //------------------------------------------------------
    // app control
    var timer: CADisplayLink! = nil
    
    // boolean to determine if the first draw has occured
    var _firstDrawOccurred = false
    var _timeSinceLastDrawPreviousTime:CFTimeInterval = 0
    
    //------------------------------------------------------
    // the time interval from the last draw
    //------------------------------------------------------
    var _timeSinceLastDraw:NSTimeInterval = 0
    
    // pause/resume
    var _gameLoopPaused:Bool = false

    //------------------------------------------------------
    // Used to pause and resume the controller.
    //------------------------------------------------------
    var paused = false
    
    // our renderer instance
    var renderer:TRenderer?

    
    //-------------------------------------------------------------------------
//    override init()
//    {
//        super.init()
//        initCommon()
//    }
    //-------------------------------------------------------------------------
    // called when loaded from nib
    //-------------------------------------------------------------------------
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initCommon()
    }
    //-------------------------------------------------------------------------
    // called when loaded from storyboard
    //-------------------------------------------------------------------------
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder:aDecoder)!
        initCommon()
    }
    //-------------------------------------------------------------------------
    func initCommon()
    {
        renderer = TRenderer()
        self.delegate = renderer!

        // Register notifications to start/stop drawing 
        // as this app moves into the background
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("didEnterBackground"),
            name: UIApplicationDidEnterBackgroundNotification,
            object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("willEnterForeground"),
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)

        interval = 1
    }
    //-------------------------------------------------------------------------
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationDidEnterBackgroundNotification,
            object:nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationWillEnterForegroundNotification,
            object: nil)

        if (timer != nil)
        {
            stopGameLoop()
        }
    }
    //-------------------------------------------------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let renderView:TView = self.view as! TView
            renderView.delegate = renderer
        
        // load all renderer assets before starting game loop
        renderer!.configure(renderView)
    }
    //-------------------------------------------------------------------------
    // used to fire off the main game loop
    //-------------------------------------------------------------------------
   func dispatchGameLoop()
    {
        //------------------------------------------------------------
        // create a game loop timer using a display link
        //------------------------------------------------------------
        timer = CADisplayLink(target: self, selector: Selector("gameloop:"))
        timer!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        timer!.frameInterval = interval
    }
    //-------------------------------------------------------------------------
    // the main game loop called by the timer above
    //-------------------------------------------------------------------------
    func gameloop(displayLink: CADisplayLink)
    {
        // tell our delegate to update itself here.
        // [_delegate update:self]
        delegate.update(self)
      
        if (!_firstDrawOccurred)
        {
            // set up timing data for display since this 
            // is the first time through this loop
            _timeSinceLastDraw             = 0.0
            _timeSinceLastDrawPreviousTime = CACurrentMediaTime()
            _firstDrawOccurred              = true
        }
        else
        {
            // figure out the time since we last we drew
            let currentTime:CFTimeInterval = CACurrentMediaTime()
            _timeSinceLastDraw = currentTime - _timeSinceLastDrawPreviousTime
            // keep track of the time interval between draws
            _timeSinceLastDrawPreviousTime = currentTime
        }
        // display (render)
        assert(view is TView)  // isKindOfClass
        
        // call the display method directly on the render view
        // (setNeedsDisplay: has been disabled in the renderview by default)
        
        let myview:TView = self.view as! TView
        myview.display()
    }
    //-------------------------------------------------------------------------
    func stopGameLoop()
    {
        // use invalidates the main game loop.
        // when the app is set to terminate
       if ( timer != nil)
        {
            timer!.invalidate()
        }
    }
    //-------------------------------------------------------------------------
    func set_Paused(pause:Bool)
    {
        if (_gameLoopPaused == true)
        {
            return
        }
        if (timer != nil)
        {
            // inform the delegate we are about to pause
            //[_delegate viewController: self willPause:pause]
            delegate.viewController(self, willPause:pause)
           
            if (pause == true)
            {
                _gameLoopPaused = true
                timer!.paused   = true
                
                // ask the view to release textures until its resumed
                //    [(AAPLView *)self.view releaseTextures]
                let myview:TView = self.view as! TView
                myview.releaseTextures()
           }
            else
            {
                _gameLoopPaused = false
                timer!.paused   = false
            }
        }
    }
    //-------------------------------------------------------------------------
    func isPaused() -> Bool
    {
       return _gameLoopPaused
    }
    //-------------------------------------------------------------------------
    func didEnterBackground(notification:NSNotification)
    {
        self.set_Paused(true)
    }
    //-------------------------------------------------------------------------
    func willEnterForeground(notification:NSNotification)
    {
        self.set_Paused(false)
    }
    //-------------------------------------------------------------------------
    override func viewWillAppear(animated:Bool)
    {
        super.viewWillAppear(animated)
        // run the game loop
        self.dispatchGameLoop()
    }
    //-------------------------------------------------------------------------
    override func viewWillDisappear(animated:Bool)
    {
        super.viewWillDisappear(animated)
        // end the gameloop
        self.stopGameLoop()
    }
    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
}
//-----------------------------------------------------------------------------
