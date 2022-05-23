using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateSun : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        //rotate y axis
        transform.rotation = Quaternion.Euler(transform.rotation.eulerAngles.x, Time.time * 20, transform.rotation.eulerAngles.z);
    }
}
