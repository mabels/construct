#![feature(custom_derive, plugin)]
#![plugin(serde_macros)]

extern crate regex;
extern crate iron;
extern crate bodyparser;
extern crate time;
extern crate persistent;
extern crate rustc_serialize;
extern crate serde_json;

pub mod apt;


//use woko::apt;
use iron::prelude::*;
//use iron::{BeforeMiddleware, AfterMiddleware, typemap};
//use time::precise_time_ns;

use persistent::Read;
use iron::status;
use iron::headers;

//use rustc_serialize::json::{self};
use rustc_serialize::json;

fn apt_process(req: &mut Request) -> IronResult<Response> {

                //println!(">-<");
    let payload = req.get::<bodyparser::Struct<apt::ReqPackageList>>();
                //println!(">+<");
        match payload {
            Ok(Some(plist)) => {
                //println!(">0<");
                let result = apt::parse(&plist);
                if result.is_err() {
                    return Ok(Response::with((status::ServiceUnavailable,
                        format!("parse error {}", result.err().unwrap()))));
                }
	        let mut resp = Response::with((status::Ok, json::encode(&result.unwrap()).unwrap()));
		resp.headers.set(headers::ContentType::json());
                return Ok(resp);
            }
            Ok(None) => return Ok(Response::with((status::ServiceUnavailable, "No Json found"))),
            Err(err) => return Ok(Response::with((status::ServiceUnavailable,
                    format!("Internal Error:{}", err)))),
//            _ => return Ok(Response::with((status::ServiceUnavailable, "unknown case")))
    }
}

const MAX_BODY_LENGTH: usize = 1024 * 1024 * 1;

fn main() {
    let mut chain = Chain::new(apt_process);
    chain.link_before(Read::<bodyparser::MaxBodyLength>::one(MAX_BODY_LENGTH));
    //chain.link_before(ResponseTime);
    //chain.link_after(ResponseTime);
    Iron::new(chain).http("0.0.0.0:7878").unwrap();
}