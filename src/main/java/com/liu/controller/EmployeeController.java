package com.liu.controller;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import com.liu.pojo.Employee;
import com.liu.pojo.Msg;
import com.liu.service.EmployeeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 处理CRUD请求
 *
 * @author root
 * @create 2020-11-10 11:10
 */
@Controller
public class EmployeeController {
    @Autowired
    EmployeeService employeeService;

    /**
     * 查询员工数据（分页查询）
     *
     * @return
     */
    // @RequestMapping("/emps")
    public String getEmps(@RequestParam(value = "pn", defaultValue = "1") Integer pn, Model model) {
//        一千条 ，采用分页           PageHelper分页插件
        PageHelper.startPage(pn, 5);
        List<Employee> employeeList = employeeService.getAll();
//        使用pageInfo包装查询的结果，只需要将pageInfo交给页面
        //封装了详细的分页信息，包括查询数据,连续传入的页数
        PageInfo page = new PageInfo(employeeList, 5);
        model.addAttribute("page", page);
        return "list";
    }

    /**
     * 要是@ResponseBody正常使用   需要导入JSON的包
     *
     * @param pn
     * @param model
     * @return
     */
    @RequestMapping("/emps")
    @ResponseBody
    public Msg getEmpsWithJson(@RequestParam(value = "pn", defaultValue = "1") Integer pn, Model model) {
//        一千条 ，采用分页           PageHelper分页插件
        PageHelper.startPage(pn, 5);
        List<Employee> employeeList = employeeService.getAll();
//        使用pageInfo包装查询的结果，只需要将pageInfo交给页面
        //封装了详细的分页信息，包括查询数据,连续传入的页数
        PageInfo page = new PageInfo(employeeList, 5);

        return Msg.success().add("pageInfo", page);
    }

    /**
     * 员工保存
     * 1.支持JSR303校验
     * 2.导入Hibernate-Validator
     *
     * @return
     */
    @RequestMapping(value = "/emp", method = RequestMethod.POST)
    @ResponseBody
    public Msg saveEmp(@Valid Employee employee, BindingResult result) {
        if (result.hasErrors()) {
            //校验失败，应该返回失败，在模态框中显示校验失败
            Map<String, Object> map = new HashMap<String, Object>();
            List<FieldError> errors = result.getFieldErrors();
            for (FieldError fieldError : errors) {
                System.out.println("错误的字段名：" + fieldError.getField());
                System.out.println("错误信息：" + fieldError.getDefaultMessage());
                map.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
            return Msg.fail();
        } else {
            employeeService.saveEmp(employee);
            return Msg.success();
        }

    }

    /**
     * 检验用户名是否可用
     */
    @RequestMapping("/checkUser")
    @ResponseBody
    public Msg checkUser(@RequestParam("empName") String empName) {
        String regx = "/^[a-zA-Z0-9_-]{4,16}$|[\u4E00-\u9FA5]/";
        if (!empName.matches(regx)) {
            return Msg.fail().add("va_msg", "用户名可以是2-5位中文或者6-16位英文和数字的组合");
        }
        Boolean b = employeeService.checkUser(empName);
        if (b) {
            return Msg.success();
        } else {
            return Msg.fail().add("va_msg", "用户名不可用");
        }
    }

    /**
     * 查询员工显示到点击修改的模态框上
     */
    @RequestMapping(value = "/emp/{id}", method = RequestMethod.GET)
    @ResponseBody
    public Msg getEmp(@PathVariable int id) {
        Employee employee = employeeService.getEmp(id);
        return Msg.success().add("emp", employee);
    }

    /**
     * 如果直接发送ajax=PUT形式的请求
     * 封装的数据
     * Employee
     * [empId=1014, empName=null, gender=null, email=null, dId=null]
     * <p>
     * 问题：
     * 请求体中有数据；
     * 但是Employee对象封装不上；
     * update tbl_emp  where emp_id = 1014;
     * <p>
     * 原因：
     * Tomcat：
     * 1、将请求体中的数据，封装一个map。
     * 2、request.getParameter("empName")就会从这个map中取值。
     * 3、SpringMVC封装POJO对象的时候。
     * 会把POJO中每个属性的值，request.getParamter("email");
     * AJAX发送PUT请求引发的血案：
     * PUT请求，请求体中的数据，request.getParameter("empName")拿不到
     * Tomcat一看是PUT不会封装请求体中的数据为map，只有POST形式的请求才封装请求体为map
     * org.apache.catalina.connector.Request--parseParameters() (3111);
     * <p>
     * protected String parseBodyMethods = "POST";
     * if( !getConnector().isParseBodyMethod(getMethod()) ) {
     * success = true;
     * return;
     * }
     * <p>
     * <p>
     * 解决方案；
     * 我们要能支持直接发送PUT之类的请求还要封装请求体中的数据
     * 1、配置上HttpPutFormContentFilter；
     * 2、他的作用；将请求体中的数据解析包装成一个map。
     * 3、request被重新包装，request.getParameter()被重写，就会从自己封装的map中取数据
     * 员工更新方法
     *
     * @param employee
     * @return 修改员工信息
     */
    @RequestMapping(value = "/emp/{empId}", method = RequestMethod.PUT)
    @ResponseBody
    public Msg saveEmp(Employee employee) {
        employeeService.updateEmp(employee);
        return Msg.success();
    }

    /**
     * 单个删除
     * 单个批量删除二合一
     * 批量删除：1-2-3
     * 单个删除：1
     */
    @RequestMapping(value = "/emp/{ids}", method = RequestMethod.DELETE)
    @ResponseBody
    public Msg deleteEmpById(@PathVariable("ids") String ids) {
        if (ids.contains("-")) {
            List<Integer> del_ids = new ArrayList<Integer>();
            String[] split = ids.split("-");
            for (String s : split) {
                del_ids.add(Integer.parseInt(s));
            }
            employeeService.deleteBatch(del_ids);
        } else {
            Integer id = Integer.parseInt(ids);
            employeeService.deleteEmp(id);

        }
        return Msg.success();
    }
}
