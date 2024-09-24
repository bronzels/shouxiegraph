import time

from FormatResp import print_resp

from nebula3.common.ttypes import ErrorCode
from nebula3.Config import SessionPoolConfig
from nebula3.gclient.net import Connection
from nebula3.gclient.net.SessionPool import SessionPool

from nebula3.gclient.net import ConnectionPool
from nebula3.Config import Config

if __name__ == "__main__":
    ip = "127.0.0.1"
    port = 9669
    
    USER = "root"
    PASSWORD = "root"
    
    try:
        config = SessionPoolConfig()
        
        conn = Connection()
        conn.open(ip, port, 1000)
        auth_result = conn.authenticate(USER, PASSWORD)
        assert auth_result.get_session_id() != 0
        resp = conn.execute(
            auth_result._session_id,
            "CREATE SPACE IF NOT EXISTS session_pool_test(vid_type=FIXED_STRING(30))",
            )
        assert resp.error_code == ErrorCode.SUCCEEDED
        time.sleep(10)
        
        session_pool = SessionPool("root", "root", "session_pool_test", [(ip, port)])
        assert session_pool.init(config)
        
        resp = session_pool.execute(
            "CREATE TAG IF NOT EXISTS person(name string, age int);"
            "CREATE EDGE like(likeness double);"
        )
        time.sleep(6)
        
        resp = session_pool.execute(
            'INSERT VERTEX person(name, age) VALUES "Bob":("Bob", 10), "Lily":("Lily", 9)'
        )
        assert resp.is_succeeded(), resp.error_msg()
        
        resp = session_pool.execute(
            'INSERT EDGE like(likeness) VALUES "Bob"->"Lily":(80.0);'
        )
        assert resp.is_succeeded(), resp.error_msg()
        
        resp = session_pool.execute(
            'FETCH PROP ON person "Bob" YIELD vertex AS node'
        )
        assert resp.is_succeeded(), resp.error_msg()
        print_resp(resp)
        
        resp = session_pool.execute(
            'FETCH PROP ON like "Bob"->"Lily" YIELD edge AS e'
        )
        assert resp.is_succeeded(), resp.error_msg()
        print_resp(resp)
        
        conn.execute(
            auth_result._session_id,
            "DROP SPACE session_pool_test"
        )
        
        print("Example finished")
    
    except Exception:
        import traceback
        
        print(traceback.format_exc())
        exit(1)
    
    connection_pool = ConnectionPool()
    connection_pool.init([(ip, port)], Config())
    
    with connection_pool.session_context(USER, PASSWORD) as session:
        session.execute_py("CREATE SPACE IF NOT EXISTS test(vid_type=FIXED_STRING(30))")
        time.sleep(10)
        session.execute_py(
            "USE test;"
            "CREATE TAG IF NOT EXISTS person(name STRING, age INT);"
            "CREATE EDGE IF NOT EXISTS like(likeness DOUBLE);"
            )
        time.sleep(20)
        session.execute_py("CLEAR SPACE test;")
        arg1 = {
            "p1": 3,
            "p2": True,
            "p3": "Bob"
        }
        stmt1 = "RETURN abs($p1)+3 AS col1, (toBoolean($p2) AND false) AS col2, toLower($p3)+1 AS col3"
        res1 = session.execute_py(stmt1, arg1)
        args2 = {
            "name1": "Bob",
            "age1": 10,
            "name2": "Lily",
            "age2": 9,
            "people": ["Bob", "Lily"]
        }
        session.execute_py(
            "USE test;"
            "INSERT VERTEX person(name, age) VALUES 'Bob':($name1, $age1), 'Lily':($name2, $age2);",
            args2
        )
        stm2 = "MATCH(v) WHERE id(v) in $people RETURN id(v) AS vertext_id"
        res2 = session.execute(stm2, args2)
        
    connection_pool.close()

