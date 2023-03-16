//
//  iTrace
//
//  Created by Fabrizio Pezzola on 11/02/2020.
//  Copyright © 2020 Fabrizio Pezzola. All rights reserved.
//

import AppKit
import ImGui

final class iTraceViewController: NSViewController {
    private var renderer = Renderer()
    
    override func loadView() {
        self.view = renderer
    }
    
    /*
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //view.addSubview(renderer)
        
        //IMGUI_CHECKVERSION();
        IMGUI_CHECKVERSION()

        //ImGui::CreateContext();
        let ctx = ImGuiCreateContext(nil)

        //ImGuiIO& io = ImGui::GetIO();
        let io = ImGuiGetIO()!

        /// Build font atlas
        var pixels: UnsafeMutablePointer<UInt8>?
        var width: Int32 = 0
        var height: Int32 = 0
        var bytesPerPixel: Int32 = 0
        // io.Fonts->GetTexDataAsRGBA32(&tex_pixels, &tex_w, &tex_h);
        ImFontAtlas_GetTexDataAsRGBA32(io.pointee.Fonts, &pixels, &width, &height, &bytesPerPixel)

        for n in 0..<20 {
            print("NewFrame() \(n)")
            // io.DisplaySize = ImVec2(1920, 1080);
            io.pointee.DisplaySize = ImVec2(x: 1920, y: 1080)
            // io.DeltaTime = 1.0f / 60.0f;
            io.pointee.DeltaTime = 1.0 / 60.0
            // ImGui::NewFrame();
            ImGuiNewFrame()
            
            var f: Float = 0.0
            // ImGui::Text("Hello, world!");
            ImGuiTextV("Hello, world!")
            // ImGui::SliderFloat("float", &f, 0.0f, 1.0f);
            ImGuiSliderFloat("float", &f, 0.0, 1.0, "", 1)
            // ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);
            ImGuiTextV("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.pointee.Framerate, io.pointee.Framerate)
            
            // ImGui::ShowDemoWindow(NULL);
            ImGuiShowDemoWindow(nil)
            
            // ImGui::Render();
            ImGuiRender()
        }

        print("DestroyContext()")
        ImGuiDestroyContext(ctx)
    }
    */
    
    func imageBegin(_ w: Int32, _ h: Int32, _ bucketSize: Int32) {
        renderer.imageBegin(w, h, bucketSize)
    }
    
    func imagePrepare(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ id: Int32) {
        renderer.imagePrepare(x, y, w, h, id)
    }
    
    func imageUpdate(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ data: [Color], _ alpha: [Float]) {
        renderer.imageUpdate(x, y, w, h, data, alpha)
    }
    
    func imageFill(_ x: Int32, _ y: Int32, _ w: Int32, _ h: Int32, _ c: Color, _ alpha: Float) {
        renderer.imageFill(x, y, w, h, c, alpha)
    }
}
