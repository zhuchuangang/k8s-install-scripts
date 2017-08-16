<#assign base=request.contextPath+"/webjars/adminlte/2.3.2"/>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Genisys | 登录</title>
    <meta name="description" content="登录">
    <meta name="author" content="zhuchuangang">
    <meta name="keyword" content="登录">
    <!--CSRF TOKEN-->
    <#--<meta name="_csrf" content="${_csrf.token}"/>-->
    <!-- default header name is X-CSRF-TOKEN -->
    <#--<meta name="_csrf_header" content="${_csrf.headerName}"/>-->
    <!-- Tell the browser to be responsive to screen width -->
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
    <!-- Bootstrap 3.3.5 -->
    <link rel="stylesheet" href="${base}/bootstrap/css/bootstrap.min.css">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.4.0/css/font-awesome.min.css">
    <!-- Ionicons -->
    <link rel="stylesheet" href="${request.contextPath}/ionicons/2.0.1/css/ionicons.min.css">
    <!-- Theme style -->
    <link rel="stylesheet" href="${base}/dist/css/AdminLTE.min.css">
    <!-- iCheck -->
    <link rel="stylesheet" href="${base}/plugins/iCheck/square/blue.css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
    <script src="${request.contextPath}/static/html5shiv/3.7.3/html5shiv.min.js"></script>
    <script src="${request.contextPath}/static/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
</head>
<body class="hold-transition login-page">
<div class="login-box">
    <div class="login-logo">
        <a href="#"><b>登录demo</a>
    </div>
    <!-- /.login-logo -->
    <div class="login-box-body">
        <#--<p class="login-box-msg">Sign in to start your session</p>-->

        <form action="${request.contextPath}/login" method="post">
            <div class="form-group has-feedback">
                <input name="username" type="text" class="form-control" placeholder="username">
                <span class="glyphicon glyphicon-envelope form-control-feedback"></span>
            </div>
            <div class="form-group has-feedback">
                <input name="password" type="password" class="form-control" placeholder="Password">
                <span class="glyphicon glyphicon-lock form-control-feedback"></span>
            </div>
            <div class="row">
                <div class="col-xs-8">
                    <div class="checkbox icheck">
                        <label>
                            <input type="checkbox"> 记住我
                        </label>
                    </div>
                </div>
                <!-- /.col -->
                <div class="col-xs-4">
                    <button type="submit" class="btn btn-primary btn-block btn-flat">登录</button>
                </div>
                <!-- /.col -->
            </div>
            <#--<input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>-->
        </form>

        <#--<a href="#">忘记密码</a><br>-->
        <#--<a href="register.html" class="text-center">注册</a>-->

    </div>
    <!-- /.login-box-body -->
</div>
<!-- /.login-box -->

<!-- jQuery 2.1.4 -->
<script src="${base}/plugins/jQuery/jQuery-2.1.4.min.js"></script>
<!-- Bootstrap 3.3.5 -->
<script src="${base}/bootstrap/js/bootstrap.min.js"></script>
<!-- iCheck -->
<script src="${base}/plugins/iCheck/icheck.min.js"></script>
<script>
    $(function () {
        $('input').iCheck({
            checkboxClass: 'icheckbox_square-blue',
            radioClass: 'iradio_square-blue',
            increaseArea: '20%' // optional
        });
    });
</script>
</body>
</html>
