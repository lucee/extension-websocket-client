/**
*
* Copyright (c) 2015, Lucee Assosication Switzerland
*
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either 
* version 2.1 of the License, or (at your option) any later version.
* 
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
* 
* You should have received a copy of the GNU Lesser General Public 
* License along with this library.  If not, see <http://www.gnu.org/licenses/>.
* 
**/
package org.lucee.extension.function;



import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;

import lucee.commons.io.res.Resource;
import lucee.loader.engine.CFMLEngine;
import lucee.loader.engine.CFMLEngineFactory;
import lucee.runtime.Component;
import lucee.runtime.PageContext;
import lucee.runtime.config.ConfigWeb;
import lucee.runtime.exp.PageException;
import lucee.runtime.ext.function.BIF;
import lucee.runtime.type.Collection;
import lucee.runtime.type.Collection.Key;
import lucee.runtime.type.Struct;
import lucee.runtime.type.UDF;
import lucee.runtime.util.Cast;
import lucee.runtime.util.Creation;
import lucee.runtime.util.HTTPUtil;

import com.neovisionaries.ws.client.WebSocket;
import com.neovisionaries.ws.client.WebSocketAdapter;
import com.neovisionaries.ws.client.WebSocketException;
import com.neovisionaries.ws.client.WebSocketExtension;
import com.neovisionaries.ws.client.WebSocketFactory;
import com.neovisionaries.ws.client.WebSocketFrame;

public class CreateWebSocketClient extends BIF {

	private static final long serialVersionUID = -6099692857454626093L;
    /**
     * The timeout value in milliseconds for socket connection.
     */
    private static final int TIMEOUT = 5000;

	@Override
	public Object invoke(PageContext pc, Object[] args) throws PageException {
		CFMLEngine engine = CFMLEngineFactory.getInstance();
		if(args.length!=2)
			throw engine.getExceptionUtil().createFunctionException(pc, "CreateWebSocketClient", 2, 2, args.length);
		return call(pc, engine.getCastUtil().toString(args[0]), engine.getCastUtil().toComponent(args[1]));
		
	}
	
	public static Object call(PageContext pc , String endpoint, Component comp) throws PageException {
		CFMLEngine engine = CFMLEngineFactory.getInstance();
		Cast caster = engine.getCastUtil();
		HTTPUtil httpUtil = CFMLEngineFactory.getInstance().getHTTPUtil();
		
		// 
		String str=engine.getStringUtil().replace(endpoint, "ws://", "http://", true, true);
		URL url;
		try {
			url = httpUtil.toURL(str);
		} catch (MalformedURLException e1) {
			throw caster.toPageException(e1);
		}
		
		try {
			return new WebSocketFactory()
			.setConnectionTimeout(TIMEOUT)
			.createSocket(endpoint)
			.addListener(new WebSocketAdapterImpl(pc.getConfig(),comp,url))
			.addExtension(WebSocketExtension.PERMESSAGE_DEFLATE)
			.connect();
		} 
		catch (Exception e) {
			throw CFMLEngineFactory.getInstance().getCastUtil().toPageException(e);
		}
	}
}

class WebSocketAdapterImpl extends WebSocketAdapter {

	private static final Collection.Key ON_ERROR;
	private static final Collection.Key ON_BINARY_MSG;
	private static final Collection.Key ON_MSG;
	private static final Collection.Key ON_CLOSE;
	private static final Collection.Key ON_PING;
	private static final Collection.Key ON_PONG;
	
	
	private static CFMLEngine engine;
	private static Cast caster;
	private static Creation creation;
	
	static {
		engine = CFMLEngineFactory.getInstance();
		caster = engine.getCastUtil();
		creation = engine.getCreationUtil();
		
		ON_ERROR = caster.toKey("onError");
		ON_MSG = caster.toKey("onMessage");
		ON_BINARY_MSG = caster.toKey("onBinaryMessage");
		ON_CLOSE = caster.toKey("onClose");
		ON_PING = caster.toKey("onPing");
		ON_PONG = caster.toKey("onPong");
		
		//CAUSE = caster.toKey("cause");
		//TYPE = caster.toKey("type");
		//MSG = caster.toKey("message");
		//DATA = caster.toKey("data");
	}
	
	private Component comp;
	private ConfigWeb config;
	private URL url;

	public WebSocketAdapterImpl(ConfigWeb config, Component comp, URL url) {
		this.config=config;
		this.comp=comp;
		this.url=url;
	}

	@Override
	public void onBinaryMessage(WebSocket websocket, byte[] binary) throws Exception {
		if(has(comp,ON_BINARY_MSG)) {
			PageContext pc=null;
			try{
				comp.call(pc=createPageContext(), ON_BINARY_MSG, new Object[]{binary});
			}
			finally {
				releasePageContext(pc);
			}
			
		}
		super.onBinaryMessage(websocket, binary);
	}

	@Override
	public void onTextMessage(WebSocket websocket, String text) throws Exception {
		try {
			if(has(comp,ON_MSG)) {
				PageContext pc=null;
				try{
					comp.call(pc=createPageContext(), ON_MSG, new Object[]{text});
				}
				finally {
					releasePageContext(pc);
				}
			}
			super.onTextMessage(websocket, text);
		
		}
		catch(Exception e) {
			e.printStackTrace();
		}
	}

	@Override
	public void onCloseFrame(WebSocket websocket, WebSocketFrame frame) throws Exception {
		if(has(comp,ON_CLOSE)) {
			PageContext pc=null;
			try {
				comp.call(pc=createPageContext(), ON_CLOSE, new Object[0]);
			}
			finally {
				releasePageContext(pc);
			}
		}
		super.onCloseFrame(websocket, frame);
	}

	@Override
	public void handleCallbackError(WebSocket websocket, Throwable cause) throws Exception {
		_onError("callback", cause,null);
		super.handleCallbackError(websocket, cause);
	}

	@Override
	public void onConnectError(WebSocket websocket, WebSocketException exception) throws Exception {
		_onError("connect", exception,null);
		super.onConnectError(websocket, exception);
	}

	@Override
	public void onError(WebSocket websocket, WebSocketException cause)throws Exception {
		_onError("general", cause,null);
		super.onError(websocket, cause);
	}

	@Override
	public void onFrameError(WebSocket websocket, WebSocketException cause, WebSocketFrame frame) throws Exception {
		_onError("frame", cause,null);
		super.onFrameError(websocket, cause, frame);
	}

	@Override
	public void onMessageError(WebSocket websocket, WebSocketException cause, List<WebSocketFrame> frames) throws Exception {
		_onError("message", cause,null);
		super.onMessageError(websocket, cause, frames);
	}

	@Override
	public void onPingFrame(WebSocket websocket, WebSocketFrame frame) throws Exception {
		if(has(comp,ON_PING)) {
			PageContext pc=null;
			try {
				comp.call(pc=createPageContext(), ON_PING, new Object[0]);
			}
			finally {
				releasePageContext(pc);
			}
		}
		super.onPingFrame(websocket, frame);
	}

	@Override
	public void onPongFrame(WebSocket websocket, WebSocketFrame frame) throws Exception {
		if(has(comp,ON_PONG)) {
			PageContext pc=null;
			try {
				comp.call(pc=createPageContext(), ON_PONG, new Object[0]);
			}
			finally {
				releasePageContext(pc);
			}
		}
		super.onPongFrame(websocket, frame);
	}

	@Override
	public void onTextMessageError(WebSocket websocket, WebSocketException cause, byte[] data) throws Exception {
		_onError("message", cause,data);
		super.onTextMessageError(websocket, cause, data);
	}

	@Override
	public void onUnexpectedError(WebSocket websocket, WebSocketException cause) throws Exception {
		_onError("unexpected", cause, null); 
		super.onUnexpectedError(websocket, cause);
	}

	private void _onError(String type, Throwable cause, Object data) throws Exception {
		List<Object> list=new ArrayList<Object>();
		list.add(type);
		list.add(cause);
		if(data!=null)list.add(data);
		
		if(has(comp,ON_ERROR)) {
			PageContext pc=null;
			try {
				comp.call(pc=createPageContext(), ON_ERROR, list.toArray());
			}
			finally {
				releasePageContext(pc);
			}
		}
	}

	private PageContext createPageContext() throws PageException {
		Resource res=config.getRootDirectory();
		File contextRoot;
		if(res instanceof File) contextRoot=(File) res;
		else contextRoot=new File(res.getAbsolutePath());
		
		try {
			return engine.createPageContext(contextRoot, url.getHost(), url.getPath(), "", null, null, null, null, null, -1, true);
		} catch (ServletException e) {
			throw caster.toPageException(e);
		}
	}

	private void releasePageContext(PageContext pc) throws PageException {
		if(pc==null) return;
		engine.releasePageContext(pc, true);
	}

	private boolean has(Component comp, Key key) {
		Object o = comp.get(key,null);
		return o instanceof UDF;
	}
}