# Docker Logs

Linux msk-1-vm-r93x 6.1.0-44-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.164-1 (2026-03-09) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/\*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Thu Apr 2 10:46:59 2026 from 188.0.130.230
root@msk-1-vm-r93x:~# docker logs diaverse-api-1 --tail 50
return obj.\_compiler_dispatch(self, **kwargs)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/sql/visitors.py", line 141, in \_compiler_dispatch
return meth(self, **kw) # type: ignore # noqa: E501
^^^^^^^^^^^^^^^^
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/sql/compiler.py", line 4679, in visit_select
compile_state = select_stmt.\_compile_state_factory(
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/sql/base.py", line 683, in create_for_statement
return klass.create_for_statement(statement, compiler, \*\*kw)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/context.py", line 1097, in create_for_statement
\_QueryEntity.to_compile_state(
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/context.py", line 2552, in to_compile_state
\_MapperEntity(
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/context.py", line 2632, in **init**
entity.\_post_inspect
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/util/langhelpers.py", line 1253, in **get**
obj.**dict**[self.__name__] = result = self.fget(obj)
^^^^^^^^^^^^^^
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/mapper.py", line 2711, in \_post_inspect
self.\_check_configure()
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/mapper.py", line 2388, in \_check_configure
\_configure_registries({self.registry}, cascade=True)
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/mapper.py", line 4204, in \_configure_registries
\_do_configure_registries(registries, cascade)
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/mapper.py", line 4245, in \_do_configure_registries
mapper.\_post_configure_properties()
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/mapper.py", line 2405, in \_post_configure_properties
prop.init()
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/interfaces.py", line 584, in init
self.do_init()
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/relationships.py", line 1642, in do_init
self.\_setup_entity()
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/relationships.py", line 1854, in \_setup_entity
self.\_clsregistry_resolve_name(argument)(),
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/clsregistry.py", line 519, in \_resolve_name
self.\_raise_for_name(name, err)
File "/usr/local/lib/python3.12/site-packages/sqlalchemy/orm/clsregistry.py", line 490, in \_raise_for_name
raise exc.InvalidRequestError(
sqlalchemy.exc.InvalidRequestError: When initializing mapper Mapper[CabAdventLine(cab_advent_lines)], expression "relationship('list[CabAdventItem]')" seems to be using a generic class as the argument to relationship(); please state the generic argument using an annotation, e.g. "items: Mapped[list['CabAdventItem']] = relationship()"

ERROR: Application startup failed. Exiting.
INFO: Waiting for child process [215]
INFO: Child process [215] died
INFO: Waiting for child process [217]
INFO: Child process [217] died
DEBUG: [RBAC] Registered cabinet RBAC SQLModel tables
DEBUG: [RBAC] Registered cabinet RBAC SQLModel tables
