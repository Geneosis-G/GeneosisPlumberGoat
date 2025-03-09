class PlumberGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var StaticMeshComponent mHatMesh;
var StaticMeshComponent mMustacheMesh;
var StaticMeshComponent mMustacheMesh2;

var bool mJumpPressed;
var float mJumpForce;

var bool mFireballActive;
var SoundCue mFireballSound;
var float mFireballSpeed;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		mHatMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( mHatMesh, 'hairSocket' );

		mMustacheMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( mMustacheMesh, 'hairSocket' );
		mMustacheMesh2.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( mMustacheMesh2, 'hairSocket' );

		gMe.JumpZ+=300;
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			ShootFireball();
		}
		if(localInput.IsKeyIsPressed("GBA_Jump", string( newKey )))
		{
			mJumpPressed=true;
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ))
		{
			mJumpPressed=false;
		}
	}
}

function OnTrickMade( GGTrickBase trickMade )
{
	local GGTrickRotation rotateTrick;

	rotateTrick = GGTrickRotation( trickMade );
	if( rotateTrick != none && rotateTrick.DidBackFlip() && abs(rotateTrick.mLastCompletedRotation.Pitch) == 2)
	{
		mFireballActive = !mFireballActive;
		myMut.WorldInfo.Game.Broadcast(myMut, "Fireballs " $ (mFireballActive?"enabled!":"disabled!"));
	}
}

function ShootFireball()
{
	local vector pos, horVel;
	local rotator rot;
	local Fireball fireball;

	if(gMe.mIsRagdoll
	|| !mFireballActive)
		return;
	//Shoot the fireball
	rot = gMe.Rotation;
	pos = GetShootLocation();
	horVel = gMe.Velocity;
	horVel.Z = 0.f;

	gMe.PlaySound(mFireballSound);
	fireball = gMe.Spawn(class'Fireball', gMe,, pos, rot,, true);
	fireball.CollisionComponent.SetRBLinearVelocity(horVel);
	fireball.ApplyImpulse(Normal(vector(rot)), mFireballSpeed, fireball.Location );
}

function OnCollision( Actor actor0, Actor actor1 )
{
	local GGPawn gpawn;

	gpawn=GGPawn(actor1);
	if(actor0 == gMe && gpawn != none)
	{
		//myMut.WorldInfo.Game.Broadcast(myMut, "OnCollision " @ gMe.mIsRagdoll @ gpawn.mIsRagdoll);
		if(!gMe.mIsRagdoll && !gpawn.mIsRagdoll)
		{
			//if jumping on head of a pawn
			//horizontal alignment
			if(DoCirclesIntersect(gMe.Location.X, gMe.Location.Y, gMe.GetCollisionRadius(), gpawn.Location.X, gpawn.Location.Y, gpawn.GetCollisionRadius()))
			{
				//myMut.WorldInfo.Game.Broadcast(myMut, "OnCollision in horizontal");
				//vertical alignment
				if((gMe.Location.Z-gMe.GetCollisionHeight()) >= (gpawn.Location.Z+gpawn.GetCollisionHeight()))
				{
					//myMut.WorldInfo.Game.Broadcast(myMut, "OnCollision in vertical");
					if(gMe.Velocity.Z <= 0.f)
					{
						//Damage pawn
						HitTarget(gpawn);
						//do bonus jump
						//myMut.WorldInfo.Game.Broadcast(myMut, "OnCollision Zspeed=" $ gMe.Velocity.Z);
						if(mJumpPressed)
						{
							//myMut.WorldInfo.Game.Broadcast(myMut, "OnCollision DoubleJumped");
							//For some reson, calling DoDoubleJump directly here do not work???
							gMe.SetTimer(0.1f, false, nameof(BonusJump), self);
						}
					}
				}
			}
		}
	}
}

function BonusJump()
{
	gMe.DoDoubleJump(false);
}

function bool DoCirclesIntersect(float centerXA, float centerYA, float radiusA, float centerXB, float centerYB, float radiusB)
{
	return (sqrt((centerXB - centerXA)*(centerXB - centerXA) + (centerYB - centerYA)*(centerYB - centerYA)) <= (radiusA + radiusB));
}

function HitTarget(Actor target)
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local vector direction, newVelocity;
	local int damage;

	direction = vect(0, 0, -1);

	gpawn = GGPawn(target);
	mmoEnemy = GGNPCMMOEnemy(target);
	zombieEnemy = GGNpcZombieGameModeAbstract(target);
	if(gpawn != none)
	{
		if(!gpawn.mIsRagdoll)
		{
			gpawn.SetRagdoll(true);
		}
		newVelocity = gpawn.mesh.GetRBLinearVelocity() + (direction * mJumpForce);
		gpawn.mesh.SetRBLinearVelocity(newVelocity);
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			damage = int(RandRange(50, 150));
			mmoEnemy.TakeDamageFrom(damage, gMe, class'GGDamageTypeExplosiveActor');
		}
		else
		{
			gpawn.TakeDamage( 0.f, gMe.Controller, gpawn.Location, vect(0, 0, 0), class'GGDamageType',, gMe);
		}
		//Damage zombies
		if(zombieEnemy != none)
		{
			damage = int(RandRange(50, 150));
			zombieEnemy.TakeDamage(damage, gMe.Controller, zombieEnemy.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode' );
		}
	}
}

function vector GetShootLocation()
{
	return gMe.Location + GetShootOffset();
}

function vector GetShootOffset()
{
	return Normal(vector(gMe.Rotation)) * gMe.GetCollisionRadius() * 1.5f;
}

defaultproperties
{
	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Heist_Props_03.mesh.Heist_Hat_01'
		Rotation=(Pitch=0, Yaw=16384, Roll=0)//16384 //32768
		Translation=(X=0, Y=5, Z=3)
		//scale=2.f
		//Materials(0)=Material'Props_01.Materials.Bicycle_Yellow_Mat'
	End Object
	mHatMesh=StaticMeshComp1

	Begin Object class=StaticMeshComponent Name=StaticMeshComp2
		StaticMesh=StaticMesh'Zombie_Food.Meshes.Food_Banana_02'
		Rotation=(Pitch=-3100, Yaw=0, Roll=0)//16384 //32768
		Translation=(X=-1.9, Y=22, Z=-10)
		Scale3D=(X=0.5, Y=0.25, Z=0.5)
		//Materials(0)=Material'Heist_Cinema_Building.Materials.Cinema_Metal_black_Mat_01'
		Materials(0)=Material'Heist_FrontEnd.Materials.Black_Mat_02'
		//Materials(0)=MaterialInstanceConstant'MMO_Props_01.Materials.Black_Iron_Mat_01'
		//Materials(0)=Material'GasStation.Materials.WallParasol_Black_Mat_01'
	End Object
	mMustacheMesh=StaticMeshComp2

	Begin Object class=StaticMeshComponent Name=StaticMeshComp3
		StaticMesh=StaticMesh'Zombie_Food.Meshes.Food_Banana_02'
		Rotation=(Pitch=3100, Yaw=0, Roll=0)//16384 //32768
		Translation=(X=1.9, Y=22, Z=-10)
		Scale3D=(X=-0.5, Y=0.25, Z=0.5)
		Materials(0)=Material'Heist_FrontEnd.Materials.Black_Mat_02'
	End Object
	mMustacheMesh2=StaticMeshComp3

	mJumpForce=1000.f

	mFireballSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Magician_Fireball_Launch_Cue'
	mFireballSpeed=200.f
}