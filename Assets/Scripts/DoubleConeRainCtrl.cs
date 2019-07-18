using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DoubleConeRainCtrl : MonoBehaviour
{
    // public
    public Camera mainCam;
    public Camera depthCam;

    public Material rain;

    private Mesh doubleCone;

    [Range(0.0f,10.0f)]
    public float rainSpeed = 1.0f;

    [Tooltip("只控制方向；用 Wind Speed 来控制风速")]
    public Vector3 windDir = new Vector3(0,0,0);

    [Range(-10.0f,10.0f)]
    public float windSpeed = 0.0f;

    [Range(0.0f, 1.0f)]
    public float windFactor = 0.0f;

    [Tooltip("只控制方向；用 Camera Move Speed 来控制移速")]
    public Vector3 mainCameraMoveDir = new Vector3(0, 0, 1);

    [Range(-10.0f, 10.0f)]
    public float mainCameraMoveSpeed = 0.0f;

    [Range(0.0f, 1.0f)]
    public float layerSpeed = 0.0f;

    [Range(0.0f, 4.0f)]
    public float layerSpiltRatio = 0.0f;

    public Vector2 tiling = new Vector2(1, 1);

    public Vector4 intensity = new Vector4(1, 1, 1, 1);
    [Range(0.0f,1.0f)]
    public float intensityFactor = 1.0f;

    [Range(100.0f,1000.0f)]
    public float mMaxDist = 300.0f;

    // private
    private Vector4 vOffset;

    // double cone mesh
    private const int NUM_MID_PART = 50;
    private const int NUM_HALF_PART = 10;
    private const float HEIGHT = 10.0f;
    private const float RADIUS = 1.0f;

    private void Awake()
    {
        InitMesh();

        transform.forward = new Vector3(0, 0, 1);

        vOffset = new Vector4(Random.value, Random.value, Random.value, Random.value);

        mainCam.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void InitMesh()
    {
        doubleCone = new Mesh();
        doubleCone.name = "Double Cone";

        const int numPointX = NUM_MID_PART + 1;
        const int numPointY = NUM_HALF_PART * 2 + 1;
        const int numPoint = numPointX * numPointY;
        const int numTri = NUM_MID_PART * NUM_HALF_PART * 2 * 2;

        var verts = new Vector3[numPoint];
        var colors = new Color[numPoint];
        var uvs = new Vector2[numPoint];
        var indices = new int[3 * numTri];

        // 从上到下，从左到右
        for (int j = 0; j < numPointY; j++)
        {
            for (int i = 0; i < numPointX; i++)
            {
                int idx = i + j * numPointX;
                float theta = i / (float)NUM_MID_PART * 2 * Mathf.PI;
                float x = Mathf.Sin(theta);
                float z = Mathf.Cos(theta);
                float y = (j / (float)(2 * NUM_HALF_PART) - 0.5f) * 2 * HEIGHT;
                float radius = (1 - (Mathf.Abs(y) / HEIGHT)) * RADIUS;
                verts[idx].Set(radius * x, y, radius * z);
            }
        }

        // color
        for(int i = 0; i < numPoint; i++)
        {
            float t = 1 - Mathf.Abs(verts[i].y) / HEIGHT;
            colors[i] = new Color(1, 1, 1, t*t*t);
        }

        // uvs
        for (int i = 0; i < numPoint; i++)
        {
            var normal = verts[i].normalized;
            float phi = Mathf.Atan2(-normal.x, -normal.z) + Mathf.PI;
            float theta = Mathf.Acos(normal.y);

            float u = phi / (2 * Mathf.PI);
            float v = theta / Mathf.PI;

            if ((i + 1) % numPointX == 0)
                u = 1.0f;

            uvs[i].Set(u, v);
        }

        for (int i = 0; i < NUM_MID_PART; i++)
        {
            for (int j = 0; j < 2 * NUM_HALF_PART; j++)
            {
                // 1 2
                // 3 4

                // 2 1 4
                indices[6 * (i + (j * NUM_MID_PART)) + 0] = (i + 1) + (j + 0) * numPointX; // 2
                indices[6 * (i + (j * NUM_MID_PART)) + 1] = (i + 0) + (j + 0) * numPointX; // 1
                indices[6 * (i + (j * NUM_MID_PART)) + 2] = (i + 1) + (j + 1) * numPointX; // 4

                // 3 4 1
                indices[6 * (i + (j * NUM_MID_PART)) + 3] = (i + 0) + (j + 1) * numPointX; // 3
                indices[6 * (i + (j * NUM_MID_PART)) + 4] = (i + 1) + (j + 1) * numPointX; // 4
                indices[6 * (i + (j * NUM_MID_PART)) + 5] = (i + 0) + (j + 0) * numPointX; // 1
            }
        }

        // assemble
        doubleCone.vertices = verts;
        doubleCone.colors = colors;
        doubleCone.SetIndices(indices, MeshTopology.Triangles, 0);
        doubleCone.uv = uvs;

        // to scene
        var meshFilter = gameObject.AddComponent<MeshFilter>();
        meshFilter.mesh = doubleCone;

        var meshRenderer = gameObject.AddComponent<MeshRenderer>();
        meshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
        meshRenderer.receiveShadows = false;
        meshRenderer.allowOcclusionWhenDynamic = false;
        meshRenderer.lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
        meshRenderer.reflectionProbeUsage = UnityEngine.Rendering.ReflectionProbeUsage.Off;
        meshRenderer.material = rain;
    }

    private void Update()
    {
        // update pos
        mainCam.transform.position += mainCameraMoveSpeed * mainCameraMoveDir.normalized * Time.deltaTime;
        transform.position = mainCam.transform.position;

        // update rotation
        var rainV = Mathf.Max(0.00001f, rainSpeed) * new Vector3(0, -1, 0);
        var windV = windSpeed * windFactor * windDir.normalized;
        var mainCamV = mainCameraMoveSpeed * mainCameraMoveDir.normalized;
        var rainDir = rainV + windV - mainCamV;

        transform.rotation *= Quaternion.FromToRotation(-transform.up, rainDir);

        // update offset
        for(int i = 0; i < 4; i++)
        {
            vOffset[i] += Time.deltaTime * layerSpeed * rainDir.magnitude;
            vOffset[i] -= Mathf.Floor(vOffset[i]);
        }

        // rain tiling
        var tilingFactor = new Vector4();
        for(int i = 0; i < 4; i++)
        {
            tilingFactor[i] = Mathf.Pow((1 + layerSpiltRatio), i);
            GetComponent<MeshRenderer>().material.SetVector("_RainST" + i,
                new Vector4(tilingFactor[i] * tiling.x, tilingFactor[i] * tiling.y, 0, -vOffset[i]));
        }

        // depth ST
        float sumTilingFactor = tilingFactor[0] + tilingFactor[1] + tilingFactor[2] + tilingFactor[3];
        float delta = Mathf.Min(mMaxDist, mainCam.farClipPlane) - mainCam.nearClipPlane;

        var bias = new Vector4();
        var scale = new Vector4();
        
        for(int i=0;i<4;i++)
            scale[i] = tilingFactor[i] / sumTilingFactor * delta;

        bias[0] = mainCam.nearClipPlane;
        bias[1] = bias[0] + scale[0];
        bias[2] = bias[1] + scale[1];
        bias[3] = bias[2] + scale[2];

        GetComponent<MeshRenderer>().material.SetVector("_DepthT", bias);
        GetComponent<MeshRenderer>().material.SetVector("_DepthS", scale);

        // intensity
        GetComponent<MeshRenderer>().material.SetVector("_Intensity", intensityFactor * intensity);

        // main camera clip space to depth camera clip space
        var depthCamW2C = depthCam.projectionMatrix * depthCam.worldToCameraMatrix;
        var mainCamW2C = mainCam.projectionMatrix * mainCam.worldToCameraMatrix;
        var mainCamClip2depthCamClip = depthCamW2C * mainCamW2C.inverse;
        GetComponent<MeshRenderer>().material.SetMatrix("_mainCamClip2depthCamClip", mainCamClip2depthCamClip);
    }
}
