using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cameraDepth : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        // 开启深度
        gameObject.GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
