//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
import Foundation
import UIKit
import Metal
import QuartzCore

//------------------------------------------------------------------------------
@objc protocol MetalViewProtocol
{
    func render(metalView : TView)
    func reshape(metalView : TView)
}
//------------------------------------------------------------------------------
class TView : UIView
{
    //-------------------------------------------------------------------------
    override class func layerClass() -> AnyClass
    {
        return CAMetalLayer.self
    }
    //-------------------------------------------------------------------------
    @IBOutlet weak var delegate: MetalViewProtocol!
    
    //------------------------------------------------------
    // view has a handle to the metal device when created
    //------------------------------------------------------
    var device:MTLDevice?
    
    //------------------------------------------------------
    // the current drawable created within the view's CAMetalLayer
    //------------------------------------------------------
    var _currentDrawable:CAMetalDrawable?
    
    //------------------------------------------------------
    // The current framebuffer can be read by delegate during
    // -[MetalViewDelegate render:]
    // This call may block until the framebuffer is available.
    //------------------------------------------------------
    var _renderPassDescriptor:MTLRenderPassDescriptor?
    
    //------------------------------------------------------
    // set these pixel formats to have the main drawable
    // framebuffer get created
    // with depth and/or stencil attachments
    //------------------------------------------------------
    var depthPixelFormat:MTLPixelFormat?
    var stencilPixelFormat:MTLPixelFormat?
    var sampleCount:Int = 1
    
    weak var metalLayer:CAMetalLayer?
    
    var layerSizeDidUpdate:Bool = false
    
    var _depthTex:MTLTexture?
    var _stencilTex:MTLTexture?
    var _msaaTex:MTLTexture?
    
    //-------------------------------------------------------------------------
    override init(frame: CGRect) // default initializer
    {
        super.init(frame: frame)
        self.initCommon()
    }
    //-------------------------------------------------------------------------
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.initCommon()
    }
    //-------------------------------------------------------------------------
    func initCommon()
    {
        self.opaque          = true
        self.backgroundColor = nil
        
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = self.layer as? CAMetalLayer
        if (metalLayer == nil)
        {
            println("NO metalLayer HERE")
        }
        metalLayer?.device = device           // 2
        metalLayer?.pixelFormat = .BGRA8Unorm // 3
        metalLayer?.framebufferOnly = true    // 4
        // this is the default but if we wanted to perform compute
        // on the final rendering layer we could set this to no
    }
    //-------------------------------------------------------------------------
    override func didMoveToWindow()
    {
        if let ns = self.window?.screen.nativeScale
        {
            self.contentScaleFactor = CGFloat(ns)
        }
    }
    //-------------------------------------------------------------------------
    // release any color/depth/stencil resources.
    // view controller will call when paused.
    //-------------------------------------------------------------------------
    func releaseTextures()
    {
        _depthTex   = nil
        _stencilTex = nil
        _msaaTex    = nil
    }
    //-------------------------------------------------------------------------
    func renderPassDescriptor() -> MTLRenderPassDescriptor?
    {
        var drawable:CAMetalDrawable? = self.currentDrawable()
        if (drawable == nil)
        {
            println(">> ERROR: Failed to get a drawable!")
            _renderPassDescriptor = nil
        }
        else
        {
            let t1 = drawable!.texture!
            setupRenderPassDescriptorForTexture(t1)
        }
        return _renderPassDescriptor?
    }
    //-------------------------------------------------------------------------
    func currentDrawable() -> CAMetalDrawable?
    {
        if (_currentDrawable == nil)
        {
            _currentDrawable = metalLayer?.nextDrawable()
        }
        return _currentDrawable?
    }
    //-------------------------------------------------------------------------
    // view controller will call off the main thread
    //-------------------------------------------------------------------------
    func display()
    {
        //------------------------------------------------------
        // Create autorelease pool per frame to avoid possible deadlock situations
        // because there are 3 CAMetalDrawables sitting in an autorelease pool.
        // handle display changes here
        //------------------------------------------------------
        if (layerSizeDidUpdate)
        {
            // set the metal layer to the drawable size in case orientation or size changes
            var drawableSize = self.bounds.size
            let sc = self.contentScaleFactor
            drawableSize.width *= sc
            drawableSize.height *= sc
            
            metalLayer?.drawableSize = drawableSize
            
            // renderer delegate method so renderer can resize anything if needed
            delegate?.reshape(self)
            
            layerSizeDidUpdate = false
        }
        
        // rendering delegate method to ask renderer to draw this frame's content
        delegate?.render(self)
        
        //------------------------------------------------------
        // do not retain current drawable beyond the frame.
        // There should be no strong references to this object 
        // outside of this view class
        //------------------------------------------------------
        _currentDrawable = nil
    }
    //-------------------------------------------------------------------------
    func setContentScaleFactor(contentScaleFactor:CGFloat)
    {
        super.contentScaleFactor = contentScaleFactor
        layerSizeDidUpdate = true
    }
    //-------------------------------------------------------------------------
    override func layoutSubviews()
    {
        super.layoutSubviews()
        layerSizeDidUpdate = true
    }
    //-------------------------------------------------------------------------
    func setupRenderPassDescriptorForTexture(texture:MTLTexture)
    {
        // create lazily
        if (_renderPassDescriptor == nil)
        {
            _renderPassDescriptor = MTLRenderPassDescriptor()
        }
        
        // create a color attachment every frame since we have to
        // recreate the texture every frame
        let colorAttachment:MTLRenderPassColorAttachmentDescriptor?
        = _renderPassDescriptor!.colorAttachments[0]!
        colorAttachment?.texture = texture
        
        // make sure to clear every frame for best performance
        colorAttachment?.loadAction = MTLLoadAction.Clear
        colorAttachment?.clearColor = MTLClearColorMake(0.65, 0.65, 0.65, 1.0)
        
        // if sample count is greater than 1, render into using MSAA,
        // then resolve into our color texture
        if (sampleCount > 1)
        {
            var doUpdate:Bool = false
            if (_msaaTex == nil)
            {
                doUpdate = true
            }
            else
            {
                doUpdate = (_msaaTex!.width != texture.width ||
                              _msaaTex!.height != texture.height ||
                               _msaaTex!.sampleCount != sampleCount)
            }
            if (doUpdate)
            {
                let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    MTLPixelFormat.BGRA8Unorm,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                desc.textureType = MTLTextureType.Type2DMultisample
                
                // sample count was specified to the view by the renderer.
                // this must match the sample count given to any pipeline
                // state using this render pass descriptor
                desc.sampleCount = sampleCount
                
                _msaaTex = device?.newTextureWithDescriptor(desc)
            }
            
            // When multisampling, perform rendering to _msaaTex, then resolve
            // to 'texture' at the end of the scene
            colorAttachment?.texture = _msaaTex
            colorAttachment?.resolveTexture = texture
            
            // set store action to resolve in this case
            colorAttachment?.storeAction = MTLStoreAction.MultisampleResolve
        }
        else
        {
            // store only attachments that will be presented to the screen, as in this case
            colorAttachment?.storeAction = MTLStoreAction.Store
        }   // color0
        
        // Now create the depth and stencil attachments
        if (depthPixelFormat != MTLPixelFormat.Invalid)
        {
            var doUpdate:Bool = false
            if (_depthTex == nil)
            {
                doUpdate = true
            }
            else
            {
                doUpdate = (_depthTex!.width != texture.width ||
                    _depthTex!.height != texture.height ||
                    _depthTex!.sampleCount != sampleCount)
            }
            
            if (doUpdate)
            {
                // If we need a depth texture and don't have one,
                // or if the depth texture we have is the wrong size
                // Then allocate one of the proper size
                let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    depthPixelFormat!,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                desc.textureType = (sampleCount > 1) ?
                    MTLTextureType.Type2DMultisample : MTLTextureType.Type2D
                
                desc.sampleCount = sampleCount
                
                _depthTex = device?.newTextureWithDescriptor(desc)
                
                let depthAttachment:MTLRenderPassDepthAttachmentDescriptor
                = _renderPassDescriptor!.depthAttachment
                depthAttachment.texture = _depthTex
                depthAttachment.loadAction = MTLLoadAction.Clear
                depthAttachment.storeAction = MTLStoreAction.DontCare
                depthAttachment.clearDepth = 1.0
            }
        } // depth
        
        if (stencilPixelFormat != MTLPixelFormat.Invalid)
        {
            var doUpdate:Bool = false
            if (_stencilTex == nil)
            {
                doUpdate = true
            }
            else
            {
                doUpdate = (_stencilTex!.width != texture.width ||
                    _stencilTex!.height != texture.height ||
                    _stencilTex!.sampleCount != sampleCount)
            }
            
            if (_stencilTex  == nil || doUpdate)
            {
                //  If we need a stencil texture and don't have one,
                //  or if the depth texture we have is the wrong size
                //  Then allocate one of the proper size
                let desc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    stencilPixelFormat!,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                desc.textureType = (sampleCount > 1) ?
                    MTLTextureType.Type2DMultisample : MTLTextureType.Type2D
                
                desc.sampleCount = sampleCount
                
                _stencilTex = device?.newTextureWithDescriptor(desc)
                
                let stencilAttachment:MTLRenderPassStencilAttachmentDescriptor
                = _renderPassDescriptor!.stencilAttachment
                
                stencilAttachment.texture = _stencilTex
                stencilAttachment.loadAction = MTLLoadAction.Clear
                stencilAttachment.storeAction = MTLStoreAction.DontCare
                stencilAttachment.clearStencil = 0
            }
        } //stencil
    }
    //-------------------------------------------------------------------------
}
//------------------------------------------------------------------------------


