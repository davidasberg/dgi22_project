using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    // Start is called before the first frame update
    public float rotateSpeed = 100f;

    public bool aroundPoint;
    public Transform target;

    void Update() {
        if(aroundPoint)
            transform.RotateAround(target.transform.position, Vector3.up, rotateSpeed * Time.deltaTime);
        else
            transform.Rotate(new Vector3(0, rotateSpeed, 0) * Time.deltaTime);
    }
}
