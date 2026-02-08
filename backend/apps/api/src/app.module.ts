import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { CampusesModule } from './campuses/campuses.module';
import { PrismaModule } from './prisma/prisma.module';
import { StoresModule } from './stores/stores.module';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), PrismaModule, CampusesModule, StoresModule],
  controllers: [AppController],
  providers: [],
})
export class AppModule {}
