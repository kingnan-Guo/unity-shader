# surface shader
是对 顶点片元着色器 的封装，在 unity 中，surface shader 是一种更高级的着色器，它封装了顶点着色器和片元着色器，使得开发者可以更方便地编写着色器。

surface shader 的语法和顶点片元着色器类似，但是有一些不同之处。surface shader 的入口函数是 `surf`，而不是 `vert` 和 `frag`。surface shader 的参数和属性可以通过 `surf` 函数的参数和属性来定义。


 #pragma surface surf Standard fullforwardshadows [optionalparams]


surface shader 的流程

1、vertex data 第一个操作函数 
在 vertex shader 中 写代码 操作顶点，然后 给 struct v2f_surf 赋值，传递给 片元着色器 fragment shader

2、在 片元着色器 （fragment shader） 里 的 拿到 struct Input 的时候，就可以去写 surface 的shader，当写 surface shader 的时候 已经 做了一些操作， 比如世界坐标已经被计算过了



3、surf 函数
在 surf 函数中，可以访问到 vertex shader 中传递过来的数据，然后进行一些计算，最后将结果赋值给 `surf` 函数的参数和属性。可以做一些 颜色值 和 一些 效果；这里 会有 input 和 output ，这时 SurfaceOutputStandard o 会对 o 进行一些 操作； 操作完成 后会计算一些 光照模型 （Standard）；最终会到 finalcolor 函数，最终 到 finalcolor 颜色输出；

在整个流程中 unity 做了很多的操作 不知道


當前 看到 50 節 ，要吐了 之後再看 ，跳到 91節課
