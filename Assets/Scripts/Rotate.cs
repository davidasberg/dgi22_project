using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    // Start is called before the first frame update
    public float rotateSpeed = 100f;
    void FixedUpdate() {
        transform.Rotate(new Vector3(rotateSpeed/2, rotateSpeed, rotateSpeed/3) * Time.deltaTime);
    }
}
