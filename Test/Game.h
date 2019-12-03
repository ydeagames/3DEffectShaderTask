//
// Game.h
//

#pragma once

#include "DeviceResources.h"
#include "StepTimer.h"
#include <SimpleMath.h>
#include <Effects.h>
#include <PrimitiveBatch.h>
#include <VertexTypes.h>
#include <CommonStates.h>
#include <Model.h>

#include "MyEffect.h"
#include "EffectManager.h"




// A basic game implementation that creates a D3D11 device and
// provides a game loop.
class Game : public DX::IDeviceNotify
{
public:

    Game();

    // Initialization and management
    void Initialize(HWND window, int width, int height);

    // Basic game loop
    void Tick();

    // IDeviceNotify
    virtual void OnDeviceLost() override;
    virtual void OnDeviceRestored() override;

    // Messages
    void OnActivated();
    void OnDeactivated();
    void OnSuspending();
    void OnResuming();
    void OnWindowMoved();
    void OnWindowSizeChanged(int width, int height);

    // Properties
    void GetDefaultSize( int& width, int& height ) const;

private:

    void Update(DX::StepTimer const& timer);
    void Render();

    void Clear();

    void CreateDeviceDependentResources();
    void CreateWindowSizeDependentResources();

    // Device resources.
    std::unique_ptr<DX::DeviceResources>    m_deviceResources;

	std::unique_ptr<DirectX::Mouse>         m_mouse;
	std::unique_ptr<DirectX::Keyboard>      m_keyboard;

    // Rendering loop timer.
    DX::StepTimer                           m_timer;


	EffectManager*							m_effectManager;

	DirectX::SimpleMath::Vector3			m_camera;
	DirectX::SimpleMath::Matrix				m_view;
	DirectX::SimpleMath::Matrix				m_proj;



};