#!/usr/local/bin/node

var sys = require("sys");
var util = require("util");
var url = require("url");
var httpAgent = require("http-agent");
var jsdom = require("jsdom").jsdom;
//var window = jsdom(agent.body).createWindow();
//var $ = require("jquery").create(window);

var baseURL = "https://campus.dpsk12.org/campus/";

// Login to Infinite Campus
loginAgent = httpAgent.create(baseURL + "verify.jsp", [{
    method: "PUT",
    uri: baseURL + "verify.jsp",
    
}]);