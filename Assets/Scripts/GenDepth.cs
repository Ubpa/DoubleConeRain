#region HeadComments
// ********************************************************************
//  Copyright (C) 2017 DefaultCompany
//  作    者：rivershen-PC4
//  文件路径：Assets/Scripts/Logical/TAModule/Mono/ShadowMapCamera.cs
//  创建日期：2017/09/25 11:37:18
//  功能描述：
//
// *********************************************************************
#endregion

using UnityEngine;
using System.Collections;

public class GenDepth : MonoBehaviour
{
    public Shader shadowShader;
    public RenderTexture depthRT;

    private void OnEnable()
    {
        GetComponent<Camera>().SetReplacementShader(shadowShader, "RenderType");
        GetComponent<Camera>().targetTexture = depthRT;
    }

    private void OnDisable()
    {
        GetComponent<Camera>().targetTexture = null;
        GetComponent<Camera>().ResetReplacementShader();
    }
}
