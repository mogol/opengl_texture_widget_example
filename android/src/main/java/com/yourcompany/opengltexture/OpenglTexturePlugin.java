package com.yourcompany.opengltexture;

import android.graphics.SurfaceTexture;
import android.util.Log;
import android.util.LongSparseArray;

import java.util.Map;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.TextureRegistry;

public class OpenglTexturePlugin implements MethodCallHandler {
    private final TextureRegistry textures;
    private LongSparseArray<OpenGLRenderer> renders = new LongSparseArray<>();

    public OpenglTexturePlugin(TextureRegistry textures) {
        this.textures = textures;
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "opengl_texture");
        channel.setMethodCallHandler(new OpenglTexturePlugin(registrar.textures()));
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Map<String, Number> arguments = (Map<String, Number>) call.arguments;
        Log.d("OpenglTexturePlugin", call.method + " " + call.arguments.toString());
        if (call.method.equals("create")) {
            TextureRegistry.SurfaceTextureEntry entry = textures.createSurfaceTexture();
            SurfaceTexture surfaceTexture = entry.surfaceTexture();

            int width = arguments.get("width").intValue();
            int height = arguments.get("height").intValue();
            surfaceTexture.setDefaultBufferSize(width, height);

            SampleRenderWorker worker = new SampleRenderWorker();
            OpenGLRenderer render = new OpenGLRenderer(surfaceTexture, worker);

            renders.put(entry.id(), render);

            result.success(entry.id());
        } else if (call.method.equals("dispose")) {
            long textureId = arguments.get("textureId").longValue();
            OpenGLRenderer render = renders.get(textureId);
            render.onDispose();
            renders.delete(textureId);
        } else {
            result.notImplemented();
        }
    }
}

