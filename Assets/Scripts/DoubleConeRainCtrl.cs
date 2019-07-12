using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// TODO
// 1. 轻微旋转
// 2. 遮挡
// 3. 关系

public class DoubleConeRainCtrl : MonoBehaviour
{
    private Mesh doubleCone;

    private const int NUM_MID_PART = 50;
    private const int NUM_HALF_PART = 10;
    private const float HEIGHT = 10.0f;
    private const float RADIUS = 1.0f;

    public Camera cam;

    [Range(0.0f,10.0f)]
    public float rainSpeed = 1.0f;

    [Tooltip("只控制方向；用 Wind Speed 来控制风速")]
    public Vector3 windDir = new Vector3(0,0,0);

    [Range(0.0f,10.0f)]
    public float windSpeed = 0.0f;

    [Tooltip("只控制方向；用 Camera Move Speed 来控制移速")]
    public Vector3 cameraMoveDir = new Vector3(0, 0, 1);

    [Range(0.0f, 10.0f)]
    public float cameraMoveSpeed = 0.0f;

    [Range(0.0f, 1.0f)]
    public float layer0SpeedFactor = 0.0f;
    private float vOffset0;

    [Range(0.0f, 1.0f)]
    public float layer1SpeedFactor = 0.0f;
    private float vOffset1;

    [Range(0.0f, 1.0f)]
    public float layer2SpeedFactor = 0.0f;
    private float vOffset2;

    [Range(0.0f, 1.0f)]
    public float layer3SpeedFactor = 0.0f;
    private float vOffset3;

    public Vector2 tiling0 = new Vector2(1, 1);
    public Vector2 tiling1 = new Vector2(1, 1);
    public Vector2 tiling2 = new Vector2(1, 1);
    public Vector2 tiling3 = new Vector2(1, 1);

    private void Awake()
    {
        InitMesh();
        transform.forward = new Vector3(0, 0, 1);

        vOffset0 = 0;
        vOffset1 = 0;
        vOffset2 = 0;
        vOffset3 = 0;
    }

    private void InitMesh()
    {
        doubleCone = new Mesh();

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
        GetComponent<MeshFilter>().mesh = doubleCone;
    }

    private void Update()
    {
        // update pos
        cam.transform.position += cameraMoveSpeed * cameraMoveDir.normalized * Time.deltaTime;
        transform.position = cam.transform.position;

        // update rotation
        var rainV = rainSpeed * new Vector3(0, -1, 0);
        var windV = Mathf.Max(0.001f, windSpeed) * windDir.normalized;
        var camV = Mathf.Max(0.001f, cameraMoveSpeed) * cameraMoveDir.normalized;
        var rainDir = (rainV + windV - camV).normalized;

        transform.rotation *= Quaternion.FromToRotation(-transform.up, rainDir);

        // update offset
        vOffset0 += Time.deltaTime * layer0SpeedFactor * rainSpeed;
        vOffset0 -= Mathf.Floor(vOffset0);
        vOffset1 += Time.deltaTime * layer1SpeedFactor * rainSpeed;
        vOffset1 -= Mathf.Floor(vOffset1);
        vOffset2 += Time.deltaTime * layer2SpeedFactor * rainSpeed;
        vOffset2 -= Mathf.Floor(vOffset2);
        vOffset3 += Time.deltaTime * layer3SpeedFactor * rainSpeed;
        vOffset3 -= Mathf.Floor(vOffset3);

        GetComponent<MeshRenderer>().material.SetVector("_ST0", new Vector4(tiling0.x, tiling0.y, 0, -vOffset0));
        GetComponent<MeshRenderer>().material.SetVector("_ST1", new Vector4(tiling1.x, tiling1.y, 0, -vOffset1));
        GetComponent<MeshRenderer>().material.SetVector("_ST2", new Vector4(tiling2.x, tiling2.y, 0, -vOffset2));
        GetComponent<MeshRenderer>().material.SetVector("_ST3", new Vector4(tiling3.x, tiling3.y, 0, -vOffset3));
    }
}
