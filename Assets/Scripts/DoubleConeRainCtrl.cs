using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DoubleConeRainCtrl : MonoBehaviour
{
    private Mesh doubleCone;

    private const int NUM_MID_PART = 50;
    private const int NUM_HALF_PART = 10;
    private const float HEIGHT = 10.0f;
    private const float RADIUS = 1.0f;

    private void Awake()
    {
        InitMesh();
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
        for (int i = 0; i < numPointX; i++)
            colors[i] = new Color(1, 1, 1, 0);
        for (int j = 1; j < numPointY - 1; j++)
        {
            for (int i = 0; i < numPointX; i++)
                colors[i + j * numPointX] = new Color(1, 1, 1, 1);
        }
        for (int i = 0; i < numPointX; i++)
            colors[i + (numPointY - 1) * numPointX] = new Color(1, 1, 1, 0);

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
}
