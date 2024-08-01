using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cameraOperation : MonoBehaviour
{
    // Start is called before the first frame update
    private Transform CenObj;//围绕的物体
    private Vector3 Rotion_Transform;
    private new Camera camera;

    private GameObject LookAtCube;
    int count = 90;
    public float time;

    private float speed = 2.0f;
    void Start()
    {
        
        print("cameraPosition ==" + this.gameObject.transform.position);

        camera = GetComponent<Camera>();
        transform.position = new Vector3(0,0, 0);



        Rotion_Transform = new Vector3(0, 0, 0);
        // camera.transform.LookAt(Rotion_Transform);
        // 创建 cube
        LookAtCube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        // 设置 cube 的位置
        LookAtCube.transform.position = Rotion_Transform;
        // 设置 cube 的颜色
        LookAtCube.GetComponent<Renderer>().material.color = Color.red;
        LookAtCube.name = "LookAtCube";



        // transform.RotateAround(LookAtCube.transform.position, Vector3.right, 20);
        // transform.RotateAround(LookAtCube.transform.position, Vector3.up, -36);

        // LookAtCube.transform.Rotate(Vector3.up, -36);
        // Debug.Log("Rotion_Transform ==" + Rotion_Transform);


    }
    void Update()
    {
        Ctrl_Cam_Move();
        Cam_Ctrl_Rotation();

        // Input.GetKey(KeyCode.Mouse2) ||
        if ( true)
        {
            Vector3 inputDir = new Vector3(0, 0, 0);
            if (Input.GetKey(KeyCode.W))
            {
                inputDir.z = +1f;
            }
            if (Input.GetKey(KeyCode.S))
            {
                inputDir.z = -1f;
            }
            if (Input.GetKey(KeyCode.A))
            {
                inputDir.x = -1f;
            }
            if (Input.GetKey(KeyCode.D))
            {
                inputDir.x = +1f;
            }
            // 设置摄像机的旋转
            // CenObj.rotation = Quaternion.Euler(CenObj.rotation.eulerAngles.x, CenObj.rotation.eulerAngles.y, 0);
            Vector3 moveDir = transform.forward * inputDir.z + transform.right * inputDir.x;
            // moveDir = new Vector3(moveDir.x, 0, moveDir.z);

            // 设置摄像机的旋转
            // if (Input.GetKey(KeyCode.Mouse2)) {
            //     // Debug.Log(transform.forward);
            //     Debug.Log("moveDir ==" + moveDir);
            // }
            float moveSpeed = 15f;
            transform.position += moveDir * moveSpeed * Time.deltaTime;
            LookAtCube.transform.position += LookAtCube.transform.right * inputDir.x * moveSpeed * Time.deltaTime;

            // LookAtCube.transform.Translate(new Vector3(data.x, 0, data.z));

            if (Input.GetMouseButton(2)){
                float mouseX = Input.GetAxis("Mouse X");
                float mouseY = Input.GetAxis("Mouse Y");

                // 横向平移
                MoveCameraSideways(mouseX);

                // 纵向平移，若相机垂直地面则向前平移
                MoveCameraUpwards(mouseY);
            }



        }





        changeCameraPosition();


    }
    //镜头的远离和接近
    public void Ctrl_Cam_Move()
    {
        if (Input.GetAxis("Mouse ScrollWheel") > 0)
        {
            transform.Translate(Vector3.forward * 3f);//速度可调  自行调整
        }
        if (Input.GetAxis("Mouse ScrollWheel") < 0)
        {
            transform.Translate(Vector3.forward * -3f);//速度可调  自行调整
        }
    }
    //摄像机的旋转
    public void Cam_Ctrl_Rotation()
    {
        var mouse_x = Input.GetAxis("Mouse X");//获取鼠标X轴移动
        var mouse_y = -Input.GetAxis("Mouse Y");//获取鼠标Y轴移动
        if (Input.GetKey(KeyCode.Mouse1))
        {
            transform.RotateAround(LookAtCube.transform.position, Vector3.up, mouse_x * speed);
            transform.RotateAround(LookAtCube.transform.position, transform.right, mouse_y * speed);

            // 旋转 Cube

            LookAtCube.transform.Rotate(Vector3.up, mouse_x * speed);
        }
    }


    // 更新相机的横向平移
    private void MoveCameraSideways(float mouseX)
    {
        // return;
        transform.Translate(Vector3.right * 50 * Time.deltaTime * -mouseX);

        Vector3 data = Vector3.right * 50 * Time.deltaTime * - mouseX;

        LookAtCube.transform.Translate(new Vector3(data.x, 0, data.z));


        

    }

    // 更新相机的纵向平移
    private void MoveCameraUpwards(float mouseY)
    {
        transform.Translate(Vector3.up * 50 * Time.deltaTime * -mouseY);
        // Rotion_Transform = (Vector3.up * 50 * Time.deltaTime * -mouseY);
        Vector3 data = Vector3.up * 50 * Time.deltaTime * -mouseY;
        // transform 旋转角度
        // 获取物体的当前旋转作为欧拉角
        Vector3 rotationAsEulerAngles = transform.eulerAngles;

        LookAtCube.transform.position = LookAtCube.transform.position + LookAtCube.transform.forward * 50 * Time.deltaTime * -mouseY; 

    }


    private void changeCameraPosition(){
        time += Time.deltaTime;
        // if ( time < 0.2f)
        // {


        // }  else {
        //     time = 0;
        // }

            if(count < 90){
                transform.RotateAround(LookAtCube.transform.position, Vector3.up, -1 * 10);
                LookAtCube.transform.Rotate(Vector3.up, -1* 10);
                count = count + 10;
            }

    }
}
