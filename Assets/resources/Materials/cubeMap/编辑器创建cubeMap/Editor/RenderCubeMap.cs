using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class RenderCubeMap : ScriptableWizard
{
    public Transform renderPos;
    public Cubemap cubemap;

    [MenuItem("Tools/createCubeMap")]
    static void CreateCubeMap(){
        ScriptableWizard.DisplayWizard<RenderCubeMap>("RenderCubeMap", "Create");
    
    }

    private void OnWizardUpdate(){
        helpString = "选择渲染位置并确定需要设置的 cubeMap";
        isValid =(renderPos != null && cubemap != null);

    }
    // 创建 回调 的方法
    
    void OnWizardCreate(){
        GameObject go = new GameObject("RenderCubeMap");
        Camera camera = go.AddComponent<Camera>();
        go.transform.position = renderPos.position;
        camera.RenderToCubemap(cubemap);
        DestroyImmediate(go);
    }
}
