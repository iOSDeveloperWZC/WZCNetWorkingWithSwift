//
//  NetWorkingWrapManager.swift
//  CocoaSwift1
//
//  Created by ataw on 16/8/29.
//  Copyright © 2016年 王宗成. All rights reserved.
//

import UIKit

class NetWorkingWrapManager: NSObject {
    
    //普通的网络接口 使用闭包传值，闭包定义格式:类型为函数类型 如果创建网络请求有错误则返回false 创建成功的网络请求 会返回true
    class func postMethod_CommonNetWorkingRequest( baseUrl baseurl:String,pathUrl:String, paramas:NSDictionary,completionblock:(anyObject:AnyObject)->Void,errorBlock:(error:NSError)->Void) ->Bool{
        
        //拼接URL
        let urlString = baseurl + pathUrl
        var resquest:NSMutableURLRequest?
        //创建URL
        if let url =  NSURL(string: urlString) {
            
            //创建请求对象
            resquest = NSMutableURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60)
            resquest?.HTTPMethod = "POST"
        }
        else
        {
            return false
        }
        
        //3.处理请求参数
        let allKeys = paramas.allKeys
        var paramsString:String = ""
        //key
        for (index,element) in allKeys.enumerate() {
            
            
            if let value = paramas["\(element)"] {
                
                paramsString += "\(element)=\(value)"
                
                if index < allKeys.count - 1{
                    
                    paramsString += "&"
                }
            }
            
        }

        print("url:\(urlString) parmas:\(paramsString)")
        resquest?.HTTPBody = paramsString.dataUsingEncoding(NSUTF8StringEncoding)
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
      
        
        let dataTask:NSURLSessionDataTask = session.dataTaskWithRequest(resquest!) { (data, responder, error) in
            
            //失败
            if error != nil
            {
                
                errorBlock(error: error!)
                return
                
            }
            
            if data != nil
            {
                
                do {
                    
                    let jsonDic = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                
                    completionblock(anyObject: jsonDic)
                    print("下发数据: \(jsonDic)")
                    
                } catch let error as NSError {
                    print("Error: \(error)")
                }
        
            }
        }
        
        dataTask.resume()
        session.finishTasksAndInvalidate()
        return true
    }
    
    //MARK:-单张图片上传接口 上传图片的时候可以带参数
    class func postMethod_SingleImageUploadToServer(baseURL baseurl:String,pathUrl:String,paramas:NSDictionary,image:UIImage,completionBlock:(anyobject:AnyObject)->Void,errorBlock:(error:NSError)->Void) -> Bool {
     
        let data = UIImagePNGRepresentation(image)
        
        //字典
        var imageDic = [String:NSData]();
        let date = NSDate()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("HHmmss")
        
        print()

        let key:String = "\(dateFormatter.stringFromDate(date))"
        let fileName:String = key+".png"
        imageDic[key] = data
        
        //拼接URL
        let urlString = baseurl + pathUrl
        var resquest:NSMutableURLRequest?
        //创建URL
        if let url =  NSURL(string: urlString) {
            
            //创建请求对象
            resquest = NSMutableURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60)
            resquest?.HTTPMethod = "POST"
        }
        else
        {
            return false
        }

        //设置请求头：请求头必须设置Content－Type : 其值必须为multipart/form-data 而且必须指明分隔符来区分多个post之间的内容
        //分界线"Boundary"
        let boundary:String =  String(format: "%08X%08X", arc4random(),arc4random())
        
        let contentType:String = "multipart/form-data;boundary="+boundary
        resquest?.addValue(contentType, forHTTPHeaderField: "Content-Type")
        resquest?.addValue(NSString(format: "\(data?.length)") as String, forHTTPHeaderField: "Content-Length")
        
        //3.处理请求参数
        let allKeys = paramas.allKeys
        var paramsString:String = ""
        //添加参数到请求体
        for (_,element) in allKeys.enumerate() {
            
            if let value = paramas["\(element)"]
            {
                paramsString += "--\(boundary)\r\n"
                paramsString += "Content-Disposition: form-data; name=\"\(element)\"\r\n\r\n"
                paramsString += "\(value)\r\n"
            }
        }
        
        //添加分界线 换行
        paramsString += "--\(boundary)\r\n"
        paramsString += "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\"\r\n"
        paramsString += "Content-Type: image/png\r\n"
        paramsString += "Content-Transfer-Encoding: binary\r\n\r\n"
        //设置请求体 \r 将当前光标移到本行开头 \n 换行，将光标移到下一个开头
        let body=NSMutableData()
        //字段添加
        body.appendData(paramsString.dataUsingEncoding(NSUTF8StringEncoding)!)
        //加图片数据
        body.appendData(data!)
        
        
        //结束分隔符
        body.appendData(NSString(format:"\r\n--\(boundary)--").dataUsingEncoding(NSUTF8StringEncoding)!)

        print("url:\(urlString) parmas:\(paramsString)")
     
        resquest?.HTTPBody = body
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        
        let dataTask:NSURLSessionDataTask = session.dataTaskWithRequest(resquest!) { (data, responder, error) in
            
            //失败
            if error != nil
            {
                errorBlock(error: error!)
                return
            }
            
            if data != nil
            {
                
                do {
                    
                    let jsonDic = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                    
                    completionBlock(anyobject: jsonDic)
                    
                    print("下发数据: \(jsonDic)")
                } catch let error as NSError {
                    print("Error: \(error)")
                }
                
            }
        }
        
        dataTask.resume()
        session.finishTasksAndInvalidate()
        return true
    }
    
    //MARK:-多图上传接口
    class func postMethod_ManyImageUploadToServer(baseURL baseurl:String,pathUrl:String,paramas:NSMutableDictionary,images:NSArray,compress:Bool,imageScale:CGSize,completionBlock:(anyobject:AnyObject)->Void,errorBlock:(error:NSError)->Void) -> Bool
    {
        
        //压缩图片
        
        let imgs = NSMutableArray()
        
        if compress {
            
            for img in images {
                
                imgs.addObject(self.scaleCompressImage(image: img as! UIImage, scaleSize: imageScale))
            }
        }
        else
        {
            for img in images {
                
                imgs.addObject(img)
            }
        }
        
        var imageDic = [String:NSData]();
        let imageDatas = NSMutableData()
        let fileNameArr = NSMutableArray()
        
        for image in imgs {
            
            if let data = UIImagePNGRepresentation(image as! UIImage)
            {
                let key:String = String(format: "img%08X", arc4random())
                let fileName:String = key+".png"
                imageDic[key] = data
                fileNameArr.addObject(fileName)
                imageDatas.appendData(data)
            }
        }
        
        //拼接URL
        let urlString = baseurl + pathUrl
        var resquest:NSMutableURLRequest?
        //创建URL
        if let url =  NSURL(string: urlString) {
            
            //创建请求对象
            resquest = NSMutableURLRequest(URL: url, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60)
            resquest?.HTTPMethod = "POST"
        }
        else
        {
            return false
        }
        
        //设置请求头：请求头必须设置Content－Type : 其值必须为multipart/form-data 而且必须指明分隔符来区分多个post之间的内容
        //分界线"Boundary"
        let boundary:String =  String(format: "%08X%08X", arc4random(),arc4random())
        
        let contentType:String = "multipart/form-data;boundary="+boundary
        resquest?.addValue(contentType, forHTTPHeaderField: "Content-Type")
        resquest?.addValue(NSString(format: "\(imageDatas.length)") as String, forHTTPHeaderField: "Content-Length")
        
        //3.处理请求参数
        let allKeys = paramas.allKeys
        var paramsString:String = ""
        //添加参数到请求体
        for (_,element) in allKeys.enumerate() {
            
            if let value = paramas["\(element)"]
            {
                paramsString += "--\(boundary)\r\n"
                paramsString += "Content-Disposition: form-data; name=\"\(element)\"\r\n\r\n"
                paramsString += "\(value)\r\n"
            }
        }
        
        let body=NSMutableData()
        //字段添加
        body.appendData(paramsString.dataUsingEncoding(NSUTF8StringEncoding)!)
        //添加分界线 换行
        var i = 0
        
        for index in imageDic {
            
            var imageString = ""
            imageString += "--\(boundary)\r\n"
            imageString += "Content-Disposition: form-data; name=\"\(index.0)\"; filename=\"\(fileNameArr[i])\"\r\n"
            imageString += "Content-Type: image/png\r\n"
            imageString += "Content-Transfer-Encoding: binary\r\n\r\n"
            //加图片数据
            body.appendData(imageString.dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData(index.1)
            i += 1
            body.appendData(NSString(format: "\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        
        //结束分隔符
        body.appendData(NSString(format:"\r\n--\(boundary)--").dataUsingEncoding(NSUTF8StringEncoding)!)
        
        print("url:\(urlString) parmas:\(paramsString)")
        
        resquest?.HTTPBody = body
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let dataTask:NSURLSessionDataTask = session.dataTaskWithRequest(resquest!) { (data, responder, error) in
            
            //失败
            if error != nil
            {
                errorBlock(error: error!)
                return
            }
            
            if data != nil
            {
                
                do {
                    
                    let jsonDic = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
                    
                    completionBlock(anyobject: jsonDic)
                    
                    print("下发数据: \(jsonDic)")
                } catch let error as NSError {
                    print("Error: \(error)")
                }
                
            }
        }
        
        dataTask.resume()
        session.finishTasksAndInvalidate()
        return true
    }
    
    //MARK:-图片压缩
    class func scaleCompressImage(image image:UIImage,scaleSize:CGSize) -> UIImage {
        
        //创建图形上下文
        UIGraphicsBeginImageContext(scaleSize)
        
        image.drawInRect(CGRectMake(0, 0, scaleSize.width, scaleSize.height))
        
        let tem = UIGraphicsGetImageFromCurrentImageContext()
        
        return tem
    }
    
}
