<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<html>
<head>
    <title>$Title$</title>
    <!-- jQuery (Bootstrap 的所有 JavaScript 插件都依赖 jQuery，所以必须放在前边) -->
    <script src="https://cdn.jsdelivr.net/npm/jquery@1.12.4/dist/jquery.min.js"></script>
    <!-- 最新版本的 Bootstrap 核心 CSS 文件 -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <!-- 最新的 Bootstrap 核心 JavaScript 文件 -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/js/bootstrap.min.js"
            integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa"
            crossorigin="anonymous"></script>
    <script type="text/javascript">
        var totalRecord, currentNum;
        //1.页面加载完成以后，直接去发送ajax请求,要到分页数据
        $(function () {
            to_page(1);
            //点击新增按钮弹出模态框。
            $("#emp_add_modal_btn").click(function () {
                //清除表单数据,(表单完整重置)
                reset_form("#empAddModal form");
                //发送ajax请求，查出部门信息，显示在下拉列表中
                getDepts("#empAddModal select");
                //弹出模态框
                $("#empAddModal").modal({
                    backdrop: "static"
                });
            });
            //用户名改变事件
            $("#empName_add_input").change(function () {
                //发送ajax请求检验用户名是否可用
                $.ajax({
                    url: "${pageContext.request.contextPath}/checkUser",
                    data: "empName=" + this.value,
                    type: "POST",
                    success: function (result) {
                        if (result.code == 100) {
                            show_validate_msg("#empName_add_input", "success", "用户名可用");
                            $("#empName_add_input").attr("ajax-va", "success");
                        } else if (result.code == 200) {
                            show_validate_msg("#empName_add_input", "error", result.extend.va_msg);
                            $("#empName_add_input").attr("ajax-va", "error");
                        }
                    }
                });
            });
            //提交事件
            $("#emp_save_btn").click(function () {
                //1.模态框中填写的表单数据提交给服务器进行保存
                //1.要对提交给服务器的数据进行检验
                if (!validate_add_form()) {
                    return false;
                }
                //1.判断之前的用户名ajax请求是否成功
                if ($(this).attr("ajax-va") == "error") {
                    return false;
                }

                //2.发送ajax请求保存员工
                // alert($("#empAddModal form").serialize());
                $.ajax({
                    url: "${pageContext.request.contextPath}/emp",
                    type: "POST",
                    data: $("#empAddModal form").serialize(),
                    success: function (result) {
                        //alert(result.msg);
                        if (result.code == 100) {
                            //1.关闭模态框
                            $("#empAddModal").modal('hide');
                            //2.来到最后一页，显示刚才保存的数据
                            to_page(totalRecord);
                        } else {
                            //显示失败信息
                            if (undefined != result.extend.errorFields.email) {
                                //显示邮箱错误信息
                                show_validate_msg("#email_add_input", "error", result.extend.errorFields.email);
                            }
                            if (undefined != result.extend.errorFields.empName) {
                                //显示用户名错误信息
                                show_validate_msg("#empName_add_input", "error", result.extend.errorFields.empName);
                            }
                        }
                    }
                });
            });
            //给修改按钮绑定单击事件
            $(document).on("click", ".edit_btn", function () {
                //alert("click");
                //0.查出员工信息，显示员工信息
                getEmp($(this).attr("edit-id"));
                //1. 查出部门信息,并显示部门列表
                getDepts("#empUpdateModal select");
                //2.显示模态框,把员工id传给模态框的更新按钮
                $("#emp_update_btn").attr("edit-id", $(this).attr("edit-id"));
                $("#empUpdateModal").modal({
                    backdrop: "static"
                });

            });
            //点击更新，更新员工信息
            $("#emp_update_btn").click(function () {
                //验证邮箱是否合法
                var email = $("#email_update_input").val();
                var regEmail = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;
                if (!regEmail.test(email)) {
                    //alert("邮箱不合法")
                    show_validate_msg("#email_update_input", "error", "邮箱格式不正确");
                    return false;
                } else {
                    show_validate_msg("#email_update_input", "success", "");
                }
                //2.发送ajax请求，保存更新的员工数据
                $.ajax({
                    url: "${pageContext.request.contextPath}/emp/" + $(this).attr("edit-id"),
                    type: "PUT",
                    data: $("#empUpdateModal form").serialize(),
                    success: function (result) {
                        //alert(result.success());
                        //1.关闭模态框
                        $("#empUpdateModal").modal('hide');
                        //2.回到修改页面
                        to_page(currentNum);
                    }
                });
            });
            //给删除按钮绑定单击事件---单个删除
            $(document).on("click", ".delete_btn", function () {
                //1.弹出是否确定删除对话框
                var empName = $(this).parents("tr").find("td:eq(2)").text();
                if (confirm("确定删除【" + empName + "】嘛？")) {
                    //确认之后发送ajax请求删除
                    $.ajax({
                        url: "${pageContext.request.contextPath}/emp/" + $(this).attr("del-id"),
                        type: "DELETE",
                        success: function (result) {
                            alert(result.msg);
                            //回到本页
                            to_page(currentNum);
                        }
                    });
                }
            });
            //完成全选/全不选功能
            $("#check_all").click(function () {
                //attr获取checked是undefined
                //我们这些dom原生的属性：attr获取自定义属性的值
                //prop修改和读取dom原生属性的值
                //alert($(this).prop("checked"));
                $(".check_item").prop("checked", $(this).prop("checked"));
            });
            //check_item
            $(document).on("click", ".check_item", function () {
                //判断当前是否被全部选中
                var flag = $(".check_item:checked").length == $(".check_item").length;

                $("#check_all").prop("checked", flag);
            })
            //点击全部删除，就批量删除
            $("#emp_delete_all_btn").click(function () {
                var empNames = "";
                var del_idstr = "";
                $.each($(".check_item:checked"), function () {
                    empNames += $(this).parents("tr").find("td:eq(2)").text() + ",";
                    del_idstr += $(this).parents("tr").find("td:eq(1)").text() + "-";
                });
                //去除empNames多余的，
                empNames = empNames.substring(0, empNames.length - 1);
                //组装员工id字符串
                del_idstr = del_idstr.substring(0, del_idstr.length - 1);
                if (confirm("确定删除【" + empNames + "】吗？")) {
                    //发送ajax请求删除
                    $.ajax({
                        url: "${pageContext.request.contextPath}/emp/" + del_idstr,
                        type: "DELETE",
                        success: function (result) {
                            alert(result.msg);
                            to_page(currentNum);
                        }
                    });
                }
            });
        });


        function to_page(pn) {
            $.ajax({
                url: "${pageContext.request.contextPath}/emps",
                data: "pn=" + pn,
                type: "GET",
                success: function (result) {
                    console.log(result);
                    //1.显示员工数据
                    build_emps_table(result);
                    //2.显示分页信息数据
                    build_page_info(result);
                    //3.显示分页条数据
                    build_page_nav(result);
                }
            });
        }

        function build_emps_table(result) {
            //清空table表格
            $("#emps_table tbody").empty();
            var emps = result.extend.pageInfo.list;
            $.each(emps, function (index, item) {
                var checkBoxTd = $("<td><input type='checkbox' class='check_item'/></td>")
                var empIdTd = $("<td></td>").append(item.empId);
                var empNameTd = $("<td></td>").append(item.empName);
                var genderTd = $("<td></td>").append(item.gender == 'M' ? "男" : "女");
                var emailTd = $("<td></td>").append(item.email);
                var deptNameTd = $("<td></td>").append(item.department.deptName);
                /**
                 <button class="">
                 <span class="" aria-hidden="true"></span>
                 编辑
                 </button>
                 */
                var editBtn = $("<button></button>").addClass("btn btn-primary btn-sm edit_btn")
                    .append($("<span></span>").addClass("glyphicon glyphicon-pencil")).append("编辑");
                //为编辑按钮添加一个自定义的属性，来表示当前员工id
                editBtn.attr("edit-id", item.empId);
                var delBtn = $("<button></button>").addClass("btn btn-danger btn-sm delete_btn")
                    .append($("<span></span>").addClass("glyphicon glyphicon-trash")).append("删除");
                //为删除按钮添加一个自定义的属性来表示当前删除的员工id
                delBtn.attr("del-id", item.empId);
                var btnTd = $("<td></td>").append(editBtn).append(" ").append(delBtn);
                //var delBtn =
                //append方法执行完成以后还是返回原来的元素
                $("<tr></tr>").append(checkBoxTd)
                    .append(empIdTd)
                    .append(empNameTd)
                    .append(genderTd)
                    .append(emailTd)
                    .append(deptNameTd)
                    .append(btnTd)
                    .appendTo("#emps_table tbody");
            });
        }

        function build_page_info(result) {
            $("#page_info_area").empty();
            $("#page_info_area").append("当前" + result.extend.pageInfo.pageNum + "页,总" +
                result.extend.pageInfo.pages + "页,总" +
                result.extend.pageInfo.total + "条记录");
            totalRecord = result.extend.pageInfo.total;
            currentNum = result.extend.pageInfo.pageNum;
        }

        function build_page_nav(result) {
            $("#page_nav_area").empty();
            var ul = $("<ul></ul>").addClass("pagination");
            //构建元素
            var firstPageLi = $("<li></li>").append($("<a></a>").append("首页").attr("href", "#"));
            var prePageLi = $("<li></li>").append($("<a></a>").append("&laquo;"));
            if (result.extend.pageInfo.hasPreviousPage == false) {
                firstPageLi.addClass("disabled");
                prePageLi.addClass("disabled");
            } else {
                //为元素添加点击翻页的事件
                firstPageLi.click(function () {
                    to_page(1);
                });
                prePageLi.click(function () {
                    to_page(result.extend.pageInfo.pageNum - 1);
                });
            }
            var nextPageLi = $("<li></li>").append($("<a></a>").append("&raquo;"));
            var lastPageLi = $("<li></li>").append($("<a></a>").append("末页").attr("href", "#"));
            if (result.extend.pageInfo.hasNextPage == false) {
                nextPageLi.addClass("disabled");
                lastPageLi.addClass("disabled");
            } else {
                nextPageLi.click(function () {
                    to_page(result.extend.pageInfo.pageNum + 1);
                });
                lastPageLi.click(function () {
                    to_page(result.extend.pageInfo.pages);
                });
            }
            //添加首页和前一页 的提示
            ul.append(firstPageLi).append(prePageLi);
            //1,2，3遍历给ul中添加页码提示
            $.each(result.extend.pageInfo.navigatepageNums, function (index, item) {

                var numLi = $("<li></li>").append($("<a></a>").append(item));
                if (result.extend.pageInfo.pageNum == item) {
                    numLi.addClass("active");
                }
                numLi.click(function () {
                    to_page(item);
                });
                ul.append(numLi);
            });
            //添加下一页和末页 的提示
            ul.append(nextPageLi).append(lastPageLi);
            //把ul加入到nav
            var navEle = $("<nav></nav>").append(ul);
            navEle.appendTo("#page_nav_area");
        }

        function getDepts(ele) {
            //清空之前下拉列表的值
            $(ele).empty();
            $.ajax({
                url: "${pageContext.request.contextPath}/depts",
                type: "GET",
                success: function (result) {
                    //显示部门信息在下拉列表中
                    $.each(result.extend.depts, function () {
                        var optionEle = $("<option></option>").append(this.deptName).attr("value", this.deptId);
                        optionEle.appendTo(ele);
                    });
                }
            });
        }

        //检验表单数据
        function validate_add_form() {
            //1.拿到要校验的数据，使用正则表达式进行校验
            var empName = $("#empName_add_input").val();
            var regName = /^[a-zA-Z0-9_-]{4,16}$|[\u4E00-\u9FA5]/;
            if (!regName.test(empName)) {
                //alert("用户名不合法");
                //应该清空这个元素之前的样式
                show_validate_msg("#empName_add_input", "error", "用户名可以是2-5位中文或者6-16位英文和数字的组合");
                return false;
            } else {
                show_validate_msg("#empName_add_input", "success", "");
            }
            var email = $("#email_add_input").val();
            var regEmail = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/;
            if (!regEmail.test(email)) {
                //alert("邮箱不合法")
                show_validate_msg("#email_add_input", "error", "邮箱格式不正确");
                return false;
            } else {
                show_validate_msg("#email_add_input", "success", "");
            }
            return true;
        }

        //显示校验结果的提示信息
        function show_validate_msg(ele, status, msg) {
            $(ele).parent().removeClass("has-success has-error");
            $(ele).next("span").text("");
            if ("success" == status) {
                $(ele).parent().addClass("has-success");
                $(ele).next("span").text(msg);
            } else if ("error" == status) {
                $(ele).parent().addClass("has-error");
                $(ele).next("span").text(msg);
            }
        }

        //表单完整重置
        function reset_form(ele) {
            $(ele)[0].reset();
            //清空表单样式
            $(ele).find("*").removeClass("has-error has-success");
            $(ele).find(".help-block").text("");
        }

        //获取员工信息
        function getEmp(id) {
            $.ajax({
                url: "${pageContext.request.contextPath}/emp/" + id,
                type: "GET",
                success: function (result) {
                    console.log(result);
                    var empData = result.extend.emp;
                    $("#empName_update_static").text(empData.empName);
                    $("#email_update_input").val(empData.email);
                    $("#empUpdateModal input[name=gender]").val([empData.gender]);
                    $("#empUpdateModal select").val([empData.dId]);
                }
            });
        }
    </script>

</head>
<body>
<%--员工添加的模态框--%>
<div id="empAddModal" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span>
                </button>
                <h4 class="modal-title">添加员工</h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal">
                    <div class="form-group">
                        <label class="col-sm-2 control-label">empName</label>
                        <div class="col-sm-10">
                            <input type="text" name="empName" class="form-control" id="empName_add_input"
                                   placeholder="empName">
                            <span class="help-block"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">email</label>
                        <div class="col-sm-10">
                            <input type="text" name="email" class="form-control" id="email_add_input"
                                   placeholder="email@atguigu.com">
                            <span class="help-block"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">gender</label>
                        <div class="col-sm-10">
                            <label class="radio-inline">
                                <input type="radio" name="gender" id="gender1_add_input" value="M" checked="checked"> 男
                            </label>
                            <label class="radio-inline">
                                <input type="radio" name="gender" id="gender2_add_input" value="F"> 女
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">deptName</label>
                        <div class="col-sm-4">
                            <!-- 部门提交部门id即可 -->
                            <select class="form-control" name="dId">
                            </select>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
                <button type="button" class="btn btn-primary" id="emp_save_btn">保存</button>
            </div>
        </div><!-- /.modal-content -->
    </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
<%--员工修改的模态框--%>
<div id="empUpdateModal" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span>
                </button>
                <h4 class="modal-title">修改员工</h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal">
                    <div class="form-group">
                        <label class="col-sm-2 control-label">empName</label>
                        <div class="col-sm-10">
                            <p class="form-control-static" id="empName_update_static"></p>
                            <span class="help-block"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">email</label>
                        <div class="col-sm-10">
                            <input type="text" name="email" class="form-control" id="email_update_input"
                                   placeholder="email@atguigu.com">
                            <span class="help-block"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">gender</label>
                        <div class="col-sm-10">
                            <label class="radio-inline">
                                <input type="radio" name="gender" id="gender1_update_input" value="M" checked="checked">
                                男
                            </label>
                            <label class="radio-inline">
                                <input type="radio" name="gender" id="gender2_update_input" value="F"> 女
                            </label>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-2 control-label">deptName</label>
                        <div class="col-sm-4">
                            <!-- 部门提交部门id即可 -->
                            <select class="form-control" name="dId">
                            </select>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
                <button type="button" class="btn btn-primary" id="emp_update_btn">更新</button>
            </div>
        </div><!-- /.modal-content -->
    </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
<div class="container">
    <%--    标题--%>
    <div class="row">
        <div class="col-md-12">
            <h1>SSM-CRUD</h1>
        </div>
    </div>
    <%--    按钮--%>
    <div class="row">
        <div class="col-md-4 col-md-offset-8">
            <button class="btn btn-primary" id="emp_add_modal_btn">新增</button>
            <button class="btn btn-danger" id="emp_delete_all_btn">删除</button>
        </div>
    </div>
    <%--    显示表格数据--%>
    <div class="row">
        <div class="col-md-12">
            <table class="table table-hover" id="emps_table">
                <thead>
                <tr>
                    <th>
                        <input type="checkbox" id="check_all">
                    </th>
                    <th>#</th>
                    <th>empName</th>
                    <th>gender</th>
                    <th>email</th>
                    <th>deptName</th>
                    <th>操作</th>
                </tr>
                </thead>
                <tbody>

                </tbody>
            </table>
        </div>
    </div>
    <%--    显示分页信息--%>
    <div class="row">
        <!--分页文字信息  -->
        <div class="col-md-6" id="page_info_area">

        </div>
        <!-- 分页条信息 -->
        <div class="col-md-6" id="page_nav_area">

        </div>
    </div>
</div>
</body>
</html>
