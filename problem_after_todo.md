# TODO:
- [ ] card in dashboard page are not correctly visible in dark mode
- [ ] plant page non funziona: errore lato server:
        2026-03-21T17:37:55.243+01:00 ERROR 849447 --- [AtixBackEnd] [nio-3333-exec-9] m.a.exceptions.ExceptionsHandler         : Unhandled exception occurred
        org.springframework.data.core.PropertyReferenceException: No property 'createdAt' found for type 'Plant'
            at org.springframework.data.core.SimplePropertyPath.<init>(SimplePropertyPath.java:93)
            at org.springframework.data.core.SimplePropertyPath.create(SimplePropertyPath.java:360)
            at org.springframework.data.core.SimplePropertyPath.create(SimplePropertyPath.java:335)
            at org.springframework.data.core.SimplePropertyPath.lambda$from$0(SimplePropertyPath.java:288)
            at org.springframework.util.ConcurrentReferenceHashMap$6.execute(ConcurrentReferenceHashMap.java:380)
            at org.springframework.util.ConcurrentReferenceHashMap$Segment.doTask(ConcurrentReferenceHashMap.java:667)
            at org.springframework.util.ConcurrentReferenceHashMap.doTask(ConcurrentReferenceHashMap.java:551)
            at org.springframework.util.ConcurrentReferenceHashMap.computeIfAbsent(ConcurrentReferenceHashMap.java:374)
- [ ] tab tutti i lavori rimane la pagina vuota
- [ ] tab tutti i lavori selezionata di default non aperti
- [ ] se c'è gia un file caricato non si vede la dimensione massima caricabile 
- [ ] 'WorksiteReference' con altro ancora non aggiungibile
        BE:
        2026-03-21T17:51:28.345+01:00  WARN 849447 --- [AtixBackEnd] [nio-3333-exec-9] org.hibernate.orm.jdbc.error             : HHH000247: ErrorCode: 0, SQLState: 23514
        2026-03-21T17:51:28.346+01:00  WARN 849447 --- [AtixBackEnd] [nio-3333-exec-9] org.hibernate.orm.jdbc.error             : ERROR: new row for relation "worksite_reference_assignments" violates check constraint "worksite_reference_assignments_role_check"
        Detail: Failing row contains (b728e832-0bbb-4e6f-8c63-040a901c8d7b, OTHER, da4c9b80-681a-4f99-bf53-13985b718754, e3c67ae0-ba8f-4016-8362-a89c8d6ac02a).
        2026-03-21T17:51:28.347+01:00  WARN 849447 --- [AtixBackEnd] [nio-3333-exec-9] .m.m.a.ExceptionHandlerExceptionResolver : Resolved [org.springframework.dao.DataIntegrityViolationException: could not execute statement [ERROR: new row for relation "worksite_reference_assignments" violates check constraint "worksite_reference_assignments_role_check"<EOL>  Detail: Failing row contains (b728e832-0bbb-4e6f-8c63-040a901c8d7b, OTHER, da4c9b80-681a-4f99-bf53-13985b718754, e3c67ae0-ba8f-4016-8362-a89c8d6ac02a).] [insert into worksite_reference_assignments (role,work_id,worksite_reference_id,id) values (?,?,?,?)]; SQL [insert into worksite_reference_assignments (role,work_id,worksite_reference_id,id) values (?,?,?,?)]; constraint [worksite_reference_assignments_role_check]]
        FE:
        	
        POST
            http://localhost:3333/api/works/da4c9b80-681a-4f99-bf53-13985b718754/add-reference
        Status
        409
        VersionHTTP/1.1
        Transferred567 B (106 B size)
        Referrer Policystrict-origin-when-cross-origin
        DNS ResolutionSystem
        API Error: 
        Object { status: 409, error: {…}, endpoint: "/works/da4c9b80-681a-4f99-bf53-13985b718754/add-reference" }
        console.ts:39:14

